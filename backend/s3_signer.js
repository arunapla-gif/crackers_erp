const crypto = require('crypto');
const fs = require('fs');
const http = require('http');
const https = require('https');

function encodeRfc3986(value) {
  return encodeURIComponent(String(value)).replace(
    /[!'()*]/g,
    (ch) => `%${ch.charCodeAt(0).toString(16).toUpperCase()}`,
  );
}

function encodeS3KeyPath(key) {
  return String(key || '')
    .replace(/^\/+/, '')
    .split('/')
    .filter((seg) => seg.length > 0)
    .map(encodeRfc3986)
    .join('/');
}

function sha256Hex(input) {
  return crypto.createHash('sha256').update(input).digest('hex');
}

function hmacSha256(key, data) {
  return crypto.createHmac('sha256', key).update(data).digest();
}

function getSigningKey(secretAccessKey, dateStamp, region, service = 's3') {
  const kDate = hmacSha256(`AWS4${secretAccessKey}`, dateStamp);
  const kRegion = hmacSha256(kDate, region);
  const kService = hmacSha256(kRegion, service);
  return hmacSha256(kService, 'aws4_request');
}

function formatAmzDates(date = new Date()) {
  const iso = date.toISOString().replace(/[:-]|\.\d{3}/g, '');
  return {
    amzDate: iso,
    dateStamp: iso.slice(0, 8),
  };
}

function resolveTarget({ endpoint, bucketName, key, urlStyle = 'virtual-host' }) {
  const parsed = new URL(endpoint);
  const basePath = parsed.pathname.replace(/\/+$/, '');
  const encodedKey = encodeS3KeyPath(key);

  if (urlStyle === 'path') {
    const objectPath = `${basePath}/${encodeRfc3986(bucketName)}/${encodedKey}`;
    return {
      protocol: parsed.protocol,
      hostname: parsed.hostname,
      port: parsed.port || undefined,
      hostHeader: parsed.host,
      objectPath,
    };
  }

  const hostHeader = `${bucketName}.${parsed.host}`;
  const hostname = `${bucketName}.${parsed.hostname}`;
  const objectPath = `${basePath}/${encodedKey}`;
  return {
    protocol: parsed.protocol,
    hostname,
    port: parsed.port || undefined,
    hostHeader,
    objectPath,
  };
}

function hashFileSha256(filePath) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('sha256');
    const stream = fs.createReadStream(filePath);
    stream.on('data', (chunk) => hash.update(chunk));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

function createPresignedGetUrl({
  endpoint,
  bucketName,
  region = 'auto',
  accessKeyId,
  secretAccessKey,
  key,
  urlStyle = 'virtual-host',
  expiresSeconds = 600,
  downloadFilename,
}) {
  if (!endpoint || !bucketName || !accessKeyId || !secretAccessKey || !key) {
    throw new Error('Missing S3 configuration or key for presigned URL');
  }

  const target = resolveTarget({ endpoint, bucketName, key, urlStyle });
  const { amzDate, dateStamp } = formatAmzDates();
  const credentialScope = `${dateStamp}/${region}/s3/aws4_request`;

  const queryParams = [
    ['X-Amz-Algorithm', 'AWS4-HMAC-SHA256'],
    ['X-Amz-Credential', `${accessKeyId}/${credentialScope}`],
    ['X-Amz-Date', amzDate],
    ['X-Amz-Expires', String(expiresSeconds)],
    ['X-Amz-SignedHeaders', 'host'],
  ];

  if (downloadFilename) {
    const cleanName = String(downloadFilename).replace(/["\r\n]/g, '');
    queryParams.push([
      'response-content-disposition',
      `attachment; filename="${cleanName}"`,
    ]);
  }

  queryParams.sort((a, b) =>
    encodeRfc3986(a[0]).localeCompare(encodeRfc3986(b[0])),
  );

  const canonicalQuery = queryParams
    .map(([k, v]) => `${encodeRfc3986(k)}=${encodeRfc3986(v)}`)
    .join('&');

  const canonicalHeaders = `host:${target.hostHeader}\n`;
  const canonicalRequest = [
    'GET',
    target.objectPath,
    canonicalQuery,
    canonicalHeaders,
    'host',
    'UNSIGNED-PAYLOAD',
  ].join('\n');

  const stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    sha256Hex(canonicalRequest),
  ].join('\n');

  const signingKey = getSigningKey(secretAccessKey, dateStamp, region, 's3');
  const signature = crypto
    .createHmac('sha256', signingKey)
    .update(stringToSign)
    .digest('hex');

  return `${target.protocol}//${target.hostHeader}${target.objectPath}?${canonicalQuery}&X-Amz-Signature=${signature}`;
}

async function putObjectStream({
  endpoint,
  bucketName,
  region = 'auto',
  accessKeyId,
  secretAccessKey,
  key,
  filePath,
  contentType = 'application/vnd.android.package-archive',
  urlStyle = 'virtual-host',
}) {
  if (!endpoint || !bucketName || !accessKeyId || !secretAccessKey || !key || !filePath) {
    throw new Error('Missing S3 upload parameters');
  }

  const stat = fs.statSync(filePath);
  const payloadHash = await hashFileSha256(filePath);
  const target = resolveTarget({ endpoint, bucketName, key, urlStyle });
  const { amzDate, dateStamp } = formatAmzDates();
  const credentialScope = `${dateStamp}/${region}/s3/aws4_request`;

  const headersToSign = {
    'content-length': String(stat.size),
    'content-type': contentType,
    host: target.hostHeader,
    'x-amz-content-sha256': payloadHash,
    'x-amz-date': amzDate,
  };

  const sortedHeaderNames = Object.keys(headersToSign).sort();
  const canonicalHeaders = sortedHeaderNames
    .map((h) => `${h}:${headersToSign[h]}\n`)
    .join('');
  const signedHeaders = sortedHeaderNames.join(';');

  const canonicalRequest = [
    'PUT',
    target.objectPath,
    '',
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');

  const stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    sha256Hex(canonicalRequest),
  ].join('\n');

  const signingKey = getSigningKey(secretAccessKey, dateStamp, region, 's3');
  const signature = crypto
    .createHmac('sha256', signingKey)
    .update(stringToSign)
    .digest('hex');

  const authorization = `AWS4-HMAC-SHA256 Credential=${accessKeyId}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;
  const transport = target.protocol === 'http:' ? http : https;

  return new Promise((resolve, reject) => {
    const req = transport.request(
      {
        protocol: target.protocol,
        hostname: target.hostname,
        port: target.port,
        path: target.objectPath,
        method: 'PUT',
        headers: {
          Host: target.hostHeader,
          'Content-Type': contentType,
          'Content-Length': String(stat.size),
          'x-amz-content-sha256': payloadHash,
          'x-amz-date': amzDate,
          Authorization: authorization,
        },
      },
      (res) => {
        const chunks = [];
        res.on('data', (d) => chunks.push(d));
        res.on('end', () => {
          const body = Buffer.concat(chunks).toString('utf8');
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({
              statusCode: res.statusCode,
              etag: res.headers.etag || null,
              key,
              sizeBytes: stat.size,
            });
          } else {
            reject(
              new Error(
                `S3 PUT failed (${res.statusCode}): ${body || res.statusMessage}`,
              ),
            );
          }
        });
      },
    );

    req.on('error', reject);
    const readStream = fs.createReadStream(filePath);
    readStream.on('error', (err) => req.destroy(err));
    readStream.pipe(req);
  });
}

module.exports = {
  createPresignedGetUrl,
  putObjectStream,
};
