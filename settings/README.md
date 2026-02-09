# Settings Folder

This folder contains environment-specific deployment settings for your solutions.

## File Naming Convention

```
settings/
├── SolutionName.settings.json       # Template (auto-generated on export)
├── SolutionName_test.json           # Test environment overrides
└── SolutionName_prod.json           # Production environment overrides
```

> 💡 See `ExampleSolution_test.json.example` and `ExampleSolution_prod.json.example` for sample formats.

## Getting Started

1. Copy an example file:
   ```bash
   cp ExampleSolution_test.json.example MySolution_test.json
   ```
2. Edit with your environment-specific values
3. Commit the file (don't include secrets!)

## Settings File Format

```json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "your_variable_name",
      "Value": "production-value"
    }
  ],
  "ConnectionReferences": [
    {
      "LogicalName": "your_connection_reference",
      "ConnectionId": "connection-id-from-target-environment"
    }
  ]
}
```

## Usage

The deployment workflow automatically uses the appropriate settings file based on the target environment.

See [Environment Configuration](../docs/environment-configuration.md) for detailed instructions.
