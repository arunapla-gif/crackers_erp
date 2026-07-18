const fs = require('fs');
const path = require('path');

const projectRoot = path.join(__dirname, '../frontend');
const viteConfigPath = path.join(projectRoot, 'vite.config.js');
const publicDir = path.join(projectRoot, 'public');
const distDir = path.join(projectRoot, 'dist');

console.log('--- Phase 2: PWA Automated Verification ---\n');
let passed = 0;
let totalChecks = 4;

// Check 1: Vite config has PWA plugin
if (fs.existsSync(viteConfigPath)) {
  const content = fs.readFileSync(viteConfigPath, 'utf8');
  if (content.includes('VitePWA') && content.includes('manifest')) {
    console.log('✅ Passed: vite.config.js is configured with VitePWA and manifest');
    passed++;
  } else {
    console.log('❌ Failed: VitePWA missing from vite.config.js');
  }
}

// Check 2: Icons exist in public folder
const requiredIcons = ['pwa-192x192.png', 'pwa-512x512.png', 'apple-touch-icon.png', 'masked-icon.svg'];
let iconsExist = true;
requiredIcons.forEach(icon => {
  if (!fs.existsSync(path.join(publicDir, icon))) {
    iconsExist = false;
    console.log(`❌ Failed: Missing icon ${icon} in public folder`);
  }
});
if (iconsExist) {
  console.log('✅ Passed: All required PWA icons exist in public directory');
  passed++;
}

// Check 3: Check if build output has the service worker
if (fs.existsSync(distDir) && fs.existsSync(path.join(distDir, 'sw.js'))) {
  console.log('✅ Passed: Service Worker (sw.js) successfully generated in dist output');
  passed++;
} else {
  console.log('❌ Failed: Service Worker (sw.js) not found in dist directory. Did the build fail?');
}

// Check 4: Check if build output has the web manifest
if (fs.existsSync(distDir) && fs.existsSync(path.join(distDir, 'manifest.webmanifest'))) {
  console.log('✅ Passed: Web App Manifest (manifest.webmanifest) successfully generated');
  passed++;
} else {
  console.log('❌ Failed: manifest.webmanifest not found in dist directory');
}

console.log(`\nResults: ${passed}/${totalChecks} passed.`);
if (passed === totalChecks) {
  console.log('🎉 PWA Architecture is perfectly configured!');
  process.exit(0);
} else {
  console.log('⚠️ PWA Configuration has errors.');
  process.exit(1);
}
