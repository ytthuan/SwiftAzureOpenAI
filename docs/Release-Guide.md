# Release Workflow Quick Reference

## 🚀 Recommended Release Process (with Human Approval)

### For Regular Releases:

1. **Push to main** (triggers automatic validation)
2. **Review validation results** in GitHub Actions
3. **Approve release** in the `release-approval` environment
4. **Release created automatically** with changelog

### For Custom Version Releases:

1. **Go to Actions** → "Release Approval Workflow" 
2. **Click "Run workflow"**
3. **Enter version** (e.g., `1.2.0`)
4. **Select type** (release/prerelease/beta/alpha)
5. **Approve when ready**

## 🔧 Environment Setup

### Required GitHub Environment:
- **Name**: `release-approval`
- **Protection rules**: Required reviewers
- **Branches**: Only `main` branch deployments

### Setting up Environment Protection:
1. Go to **Settings** → **Environments**
2. Create **"release-approval"** environment
3. Add **required reviewers** (repository maintainers)
4. Enable **"Required reviewers"** protection rule
5. Set **deployment branches** to `main` only

## 📋 Validation Checklist

The automated validation checks:
- ✅ Package structure validity
- ✅ Zero external dependencies
- ✅ Clean builds (debug & release)
- ✅ All 85+ tests passing
- ✅ No build warnings
- ✅ Required files (README.md, LICENSE)
- ✅ Swift 6.0+ compatibility

## 🏷️ Version Formats Supported

- `1.0.0` - Stable release
- `1.0.0-beta` - Beta release (prerelease)
- `1.0.0-rc1` - Release candidate (prerelease)
- `1.0.0-alpha` - Alpha release (prerelease)
- `v1.0.0` - With 'v' prefix (also supported)

## 🔄 Workflow Files

- **`.github/workflows/release-approval.yml`** - New approval workflow
- **`.github/workflows/release.yml`** - Enhanced release automation
- **`.github/workflows/ci.yml`** - Continuous integration

## 📚 Documentation

- **`docs/CI-CD.md`** - Complete CI/CD documentation
- **`scripts/prepare-release.sh`** - Manual validation script

## 🆘 Troubleshooting

### If validation fails:
1. Check the validation output in GitHub Actions
2. Fix issues in your code
3. Push changes to main
4. Validation will run again automatically

### If approval is stuck:
1. Check if reviewers have been notified
2. Ensure the environment is configured correctly
3. Verify branch protection rules

### Emergency release (bypass approval):
```bash
git tag v1.0.0
git push origin v1.0.0
```
⚠️ **Use with caution** - bypasses all approval gates

## 🎯 Best Practices

1. **Always use approval workflow** for production releases
2. **Test thoroughly** before pushing to main
3. **Use semantic versioning** (major.minor.patch)
4. **Use prereleases** for testing (beta, alpha, rc)
5. **Document changes** in meaningful commit messages
6. **Review validation results** before approval