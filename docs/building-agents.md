# Building Copilot Studio Agents

Best practices and guidance for developing agents with proper ALM in mind.

## Development Workflow

### Recommended Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Develop    │────▶│   Export    │────▶│   Review    │────▶│   Deploy    │
│  in DEV     │     │   to Git    │     │   PR        │     │   to TEST   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                   │
                                                                   ▼
                                                            ┌─────────────┐
                                                            │   Deploy    │
                                                            │   to PROD   │
                                                            └─────────────┘
```

1. **Develop** - Build your agent in the development environment
2. **Export** - Run the export workflow to capture changes
3. **Review** - Review the PR, check for unintended changes
4. **Deploy** - Merge to deploy to test, then production

## Agent Structure

When you export a Copilot Studio agent, you'll see this structure:

```
solutions/YourSolution/
├── botcomponents/
│   ├── youragent.topic.Greeting/
│   │   └── botcomponent.xml          # Topic definition
│   ├── youragent.topic.Fallback/
│   ├── youragent.action.CustomAction/
│   └── youragent.gpt.default/        # GPT configuration
├── bots/
│   └── youragent/
│       └── bot.xml                   # Agent definition
├── Connectors/
│   └── CustomConnector/              # Custom connectors
├── environmentvariabledefinitions/
│   └── yourvariable/                 # Environment variables
└── Other/
    └── Solution.xml                  # Solution metadata
```

## Best Practices

### 1. One Agent Per Solution

> ⚠️ **Critical for Scalability**: Always maintain a **1:1 relationship** between agents and solutions.

**Why?**
- Independent deployment cycles for each agent
- Smaller, faster deployments
- Easier rollbacks
- Clearer ownership and change tracking
- Avoids deployment conflicts

**Do this:**
```
solutions/
├── CustomerSupportAgent/     # One solution
│   └── bots/customer-support-agent/
├── HRAssistantAgent/         # Another solution
│   └── bots/hr-assistant-agent/
└── ITHelpdeskAgent/          # Third solution
    └── bots/it-helpdesk-agent/
```

**Avoid this:**
```
solutions/
└── AllMyAgents/              # ❌ Multiple agents in one solution
    └── bots/
        ├── customer-support-agent/
        ├── hr-assistant-agent/
        └── it-helpdesk-agent/
```

### 2. Use Descriptive Names

```
✅ Good: cust_OrderStatusTopic
❌ Bad: topic1
```

- Use prefixes to identify your components
- Be descriptive but concise
- Follow consistent naming conventions

### 3. Leverage Environment Variables

Store configuration that changes between environments:

- API endpoints
- Feature flags
- Connection references

```yaml
# In your settings file
{
  "EnvironmentVariables": [
    {
      "SchemaName": "yoursolution_APIEndpoint",
      "Value": "https://api.prod.example.com"
    }
  ]
}
```

### 4. Modular Topic Design

Break complex conversations into smaller, reusable topics:

```
Main Topic
├── Subtopic: Gather Information
├── Subtopic: Validate Input
├── Subtopic: Process Request
└── Subtopic: Confirm Result
```

### 5. Error Handling

Always include:
- Fallback topic for unrecognized inputs
- Error handling topic for failures
- Escalation path to human agents

### 6. Version Your Solutions

Increment version numbers meaningfully:

```
1.0.0.0  - Initial release
1.0.1.0  - Bug fixes
1.1.0.0  - New features
2.0.0.0  - Breaking changes
```

## Working with Topics

### Topic File Structure

Each topic is stored as XML:

```xml
<!-- botcomponent.xml -->
<BotComponent>
  <Name>Greeting</Name>
  <Description>Welcome message for users</Description>
  <!-- Topic logic in YAML-like format -->
</BotComponent>
```

### Reviewing Topic Changes

When reviewing PRs, look for:
- Trigger phrase changes
- Message content updates
- Variable modifications
- Action calls

## Working with Actions

### Custom Actions

Actions let your agent call external services:

```
Agent → Action → Connector → External API
```

Best practices:
- Use Power Automate flows for complex logic
- Keep actions focused and single-purpose
- Handle errors gracefully

### Connection References

Store connections separately from the solution:

```yaml
# settings/prod.json
{
  "ConnectionReferences": [
    {
      "LogicalName": "yoursolution_shared_customapi",
      "ConnectionId": "shared-customapi-xxx-xxx"
    }
  ]
}
```

## Testing Your Agent

### Before Exporting

1. Test all conversation paths
2. Verify error handling
3. Check integration points
4. Review analytics for issues

### After Deployment

1. Run smoke tests in test environment
2. Verify connections work
3. Test with sample users
4. Monitor for errors

## Common Patterns

### Multi-Language Support

Structure your solution for localization:

```
topics/
├── en-US/
│   ├── Greeting
│   └── Help
└── es-ES/
    ├── Greeting
    └── Help
```

### Feature Flags

Use environment variables to toggle features:

```
Topic: NewFeature
Condition: If env_NewFeatureEnabled = true
  → Show new experience
Else
  → Show standard experience
```

### A/B Testing

Deploy variations to test environments:

1. Create variants as separate topics
2. Use environment variables to control routing
3. Monitor analytics
4. Promote winner to production

## Troubleshooting Development Issues

### "Solution import failed"

- Check for missing dependencies
- Verify component naming
- Review solution checker results

### "Topic not triggering"

- Check trigger phrases
- Verify topic is enabled
- Review for conflicts with other topics

### "Action failing"

- Test connector independently
- Check connection reference
- Verify API permissions

## Resources

- [Copilot Studio Documentation](https://learn.microsoft.com/en-us/microsoft-copilot-studio/)
- [Power Platform CLI Reference](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/)
- [Solution Concepts](https://learn.microsoft.com/en-us/power-platform/alm/solution-concepts-alm)
