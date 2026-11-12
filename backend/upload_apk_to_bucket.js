const fs = require('fs');
const path = require('path');
const { putObjectStream } = require('./s3_signer');

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token.startsWith('--')) {
      const key = token.slice(2);
      const val = argv[i + 1];
      if (val === undefined || val.startsWith('--')) {
        args[key] = true;
      } else {
        args[key] = val;
        i += 1;
      }
    }
  }
  return args;
}

function readStdin() {
  return fs.readFileSync(0, 'utf8');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const filePath = args.file;
  if (!filePath || !fs.existsSync(filePath)) {
    throw new Error('Provide an existing APK via --file <path>');
  }

  let creds = {};
  if (args['credentials-json']) {
    const raw =
      args['credentials-json'] === '-'
        ? readStdin()
        : fs.readFileSync(args['credentials-json'], 'utf8');
    creds = JSON.parse(raw);
  }

  const endpoint = creds.endpoint || process.env.AWS_ENDPOINT_URL;
  const bucketName = creds.bucketName || process.env.AWS_S3_BUCKET_NAME;
  const region = creds.region || process.env.AWS_DEFAULT_REGION || 'auto';
  const accessKeyId = creds.accessKeyId || process.env.AWS_ACCESS_KEY_ID;
  const secretAccessKey =
    creds.secretAccessKey || process.env.AWS_SECRET_ACCESS_KEY;
  const urlStyle =
    creds.urlStyle || process.env.AWS_S3_URL_STYLE || 'virtual-host';

  const objectKey = args.key || `releases/${path.basename(filePath)}`;
  const result = await putObjectStream({
    endpoint,
    bucketName,
    region,
    accessKeyId,
    secretAccessKey,
    key: objectKey,
    filePath,
    urlStyle,
  });

  console.log(
    JSON.stringify({
      ok: true,
      bucketName,
      key: result.key,
      sizeBytes: result.sizeBytes,
      etag: result.etag,
    }),
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
