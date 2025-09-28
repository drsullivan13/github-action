# GitHub Action Workflow Trigger & Cross-Repo PR Creation

An API service that triggers GitHub Action workflows to automatically create Pull Requests in external repositories with specified code changes.

## 🚀 Features

- **REST API** for triggering cross-repo PR creation
- **Open API access** (no authentication required)
- **Input validation** and error handling
- **Branch collision avoidance** with automatic unique naming
- **Comprehensive logging** and monitoring
- **Rate limiting** and security headers
- **Graceful error handling** for various failure scenarios

## 📋 Requirements

- Node.js 18+
- GitHub repository with Actions enabled
- GitHub Personal Access Token with appropriate permissions

## 🛠️ Setup Instructions

### 1. Clone and Install Dependencies

```bash
git clone <your-repo-url>
cd github-action
npm install
```

### 2. Environment Configuration

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# API Configuration
PORT=3000
NODE_ENV=development

# Security
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# GitHub Configuration
GITHUB_REPO=your-username/this-repo-name
GITHUB_TOKEN=your-github-personal-access-token
```

### 3. GitHub Secrets Setup

Add the following secrets to your GitHub repository settings (`Settings > Secrets and variables > Actions`):

- **`TARGET_REPO_TOKEN`**: GitHub Personal Access Token with `repo` scope for target repositories

### 4. GitHub Token Permissions

Your GitHub tokens need these scopes:

- **`GITHUB_TOKEN`** (for triggering workflows): `repo`, `workflow`
- **`TARGET_REPO_TOKEN`** (for creating PRs): `repo`

## 🚦 Usage

### Starting the Server

```bash
# Development
npm run dev

# Production
npm start
```

### API Endpoints

#### Health Check
```http
GET /health
```

#### Service Status
```http
GET /api/status
```

#### Trigger PR Workflow
```http
POST /api/trigger-pr-workflow
Content-Type: application/json
```

### Request Payload

```json
{
  "target_repo": "owner/repository-name",
  "branch_name": "feature/my-feature",
  "file_changes": {
    "path/to/file.js": "file content here",
    "README.md": "# Updated README\\n\\nNew content..."
  },
  "commit_message": "Add new features\\n\\n- Feature 1\\n- Feature 2",
  "pr_title": "Add awesome new features",
  "pr_body": "## Summary\\n\\nThis PR adds new features..."
}
```

### Response

Success (202 Accepted):
```json
{
  "success": true,
  "message": "GitHub Action workflow triggered successfully",
  "data": {
    "target_repo": "owner/repository-name",
    "branch_name": "feature/my-feature-1640995200000",
    "request_id": "req-1640995200000",
    "status": "triggered"
  }
}
```

Error (400/401/500):
```json
{
  "error": {
    "message": "Error description",
    "details": ["Additional error details"]
  }
}
```

## 🧪 Testing

### Manual Testing

1. **Health Check**:
   ```bash
   curl http://localhost:3000/health
   ```

2. **Service Status**:
   ```bash
   curl http://localhost:3000/api/status
   ```

3. **Trigger Workflow**:
   ```bash
   curl -X POST http://localhost:3000/api/trigger-pr-workflow \\
     -H "Authorization: Bearer your-api-token" \\
     -H "Content-Type: application/json" \\
     -d @examples/sample-payload.json
   ```

### Example Payload

See `examples/sample-payload.json` for a complete example request.

## 🔒 Security

- **Authentication**: Bearer token required for API access
- **Rate limiting**: 100 requests per 15 minutes per IP
- **Input validation**: Comprehensive validation using Joi
- **Path traversal protection**: File paths are validated to prevent directory traversal
- **CORS configuration**: Configurable allowed origins
- **Security headers**: Helmet.js for security headers

## 📊 Monitoring

### Logs

The application logs all requests and workflow triggers:

```
✅ Workflow triggered for owner/repo, branch: feature-123456789
❌ Error triggering workflow: Invalid token
```

### Health Monitoring

- `/health` - Service health status
- `/api/status` - Configuration validation and service readiness

## 🐛 Troubleshooting

### Common Issues

1. **"GitHub authentication failed"**
   - Check that `GITHUB_TOKEN` is valid and has `repo` + `workflow` scopes
   - Verify `GITHUB_REPO` is set to the correct repository

2. **"GitHub repository not found"**
   - Ensure `GITHUB_REPO` format is correct (`owner/repo`)
   - Verify the token has access to the repository

3. **"Branch already exists"**
   - The system automatically adds timestamps to avoid collisions
   - Check if there are existing branches with similar names

4. **"Invalid file path"**
   - File paths cannot contain `..` or start with `/`
   - Use relative paths from repository root

5. **"Missing environment variables"**
   - Check `/api/status` endpoint for missing configuration
   - Ensure all required variables are set in `.env`

### Workflow Debugging

Monitor workflow execution in GitHub Actions:
1. Go to your repository on GitHub
2. Click "Actions" tab
3. Look for "Create Cross-Repo Pull Request" workflows
4. Check logs for detailed error information

## 🏗️ Architecture

```
┌─────────────────┐    HTTP     ┌─────────────────┐
│   Client API    │ ─────────── │  Express Server │
│    Request      │             │   (this repo)   │
└─────────────────┘             └─────────────────┘
                                          │
                                          │ Repository Dispatch
                                          ▼
                                ┌─────────────────┐
                                │ GitHub Actions  │
                                │   Workflow      │
                                └─────────────────┘
                                          │
                                          │ Git Operations
                                          ▼
                                ┌─────────────────┐
                                │  Target Repo    │
                                │   + New PR      │
                                └─────────────────┘
```

## 📝 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request