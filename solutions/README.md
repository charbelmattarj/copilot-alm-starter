# Solutions Folder

This folder contains your unpacked Power Platform solutions.

## Structure

Each solution should be in its own subfolder:

```
solutions/
├── MySolution/
│   ├── botcomponents/    # Copilot Studio topics, actions, etc.
│   ├── bots/             # Agent definitions
│   ├── Connectors/       # Custom connectors
│   ├── environmentvariabledefinitions/
│   └── Other/
│       └── Solution.xml  # Solution metadata
└── AnotherSolution/
    └── ...
```

## Adding a Solution

1. Run the **Export Solution** workflow
2. The solution will be automatically unpacked here
3. Review and commit the changes

## Manual Export

If you prefer to export manually:

```bash
# Export from environment
pac solution export --name YourSolution --path ./export --managed false

# Unpack to this folder
pac solution unpack --zipfile ./export/YourSolution.zip --folder ./solutions/YourSolution
```
