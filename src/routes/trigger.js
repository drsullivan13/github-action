const express = require('express');
const axios = require('axios');
const Joi = require('joi');
const router = express.Router();

// Input validation schema
const triggerSchema = Joi.object({
  target_repo: Joi.string().pattern(/^[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+$/).required()
    .messages({
      'string.pattern.base': 'target_repo must be in format "owner/repo"'
    }),
  branch_name: Joi.string().min(1).max(250).required(),
  file_changes: Joi.object().pattern(
    Joi.string(),
    Joi.string()
  ).min(1).required(),
  commit_message: Joi.string().min(1).max(500).required(),
  pr_title: Joi.string().min(1).max(250).required(),
  pr_body: Joi.string().max(65536).default('')
});

// POST /api/trigger-pr-workflow
router.post('/trigger-pr-workflow', async (req, res) => {
  try {
    // Validate input
    const { error, value } = triggerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        error: {
          message: 'Invalid input',
          details: error.details.map(d => d.message)
        }
      });
    }

    const {
      target_repo,
      branch_name,
      file_changes,
      commit_message,
      pr_title,
      pr_body
    } = value;

    // Generate unique branch name to avoid collisions
    const timestamp = Date.now();
    const uniqueBranchName = `${branch_name}-${timestamp}`;

    // Prepare payload for GitHub repository dispatch
    const dispatchPayload = {
      event_type: 'create-pr',
      client_payload: {
        target_repo,
        branch_name: uniqueBranchName,
        file_changes,
        commit_message,
        pr_title,
        pr_body,
        request_id: `req-${timestamp}`
      }
    };

    // Debug logging for environment variables
    console.log('🔍 DEBUG: Environment variables check:');
    console.log('GITHUB_REPO:', process.env.GITHUB_REPO);
    console.log('GITHUB_TOKEN configured:', !!process.env.GITHUB_TOKEN);
    console.log('GITHUB_TOKEN length:', process.env.GITHUB_TOKEN ? process.env.GITHUB_TOKEN.length : 0);
    console.log('Request URL:', `https://api.github.com/repos/${process.env.GITHUB_REPO}/dispatches`);

    // Trigger GitHub Action via repository dispatch
    const githubResponse = await axios.post(
      `https://api.github.com/repos/${process.env.GITHUB_REPO}/dispatches`,
      dispatchPayload,
      {
        headers: {
          'Authorization': `token ${process.env.GITHUB_TOKEN}`,
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json'
        }
      }
    );

    console.log(`✅ Workflow triggered for ${target_repo}, branch: ${uniqueBranchName}`);

    res.status(202).json({
      success: true,
      message: 'GitHub Action workflow triggered successfully',
      data: {
        target_repo,
        branch_name: uniqueBranchName,
        request_id: `req-${timestamp}`,
        status: 'triggered'
      }
    });

  } catch (error) {
    console.error('Error triggering workflow:', error);

    if (error.response?.status === 401) {
      return res.status(500).json({
        error: {
          message: 'GitHub authentication failed. Check GITHUB_TOKEN configuration.'
        }
      });
    }

    if (error.response?.status === 404) {
      return res.status(500).json({
        error: {
          message: 'GitHub repository not found. Check GITHUB_REPO configuration.'
        }
      });
    }

    res.status(500).json({
      error: {
        message: 'Failed to trigger workflow',
        details: error.message
      }
    });
  }
});

// GET /api/status - Check service status
router.get('/status', (req, res) => {
  const requiredEnvVars = ['GITHUB_TOKEN', 'GITHUB_REPO'];
  const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

  res.json({
    service: 'github-action-pr-trigger',
    status: missingVars.length === 0 ? 'ready' : 'configuration_error',
    configuration: {
      github_repo: process.env.GITHUB_REPO || 'not_configured',
      github_token_configured: !!process.env.GITHUB_TOKEN,
      missing_variables: missingVars
    },
    timestamp: new Date().toISOString()
  });
});

module.exports = router;