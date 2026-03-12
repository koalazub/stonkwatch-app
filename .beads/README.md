# Beads - stonkwatch-app

AI-native project management for the iOS companion app.

## Issue Types
- **epic**: Large initiatives (Living Briefing, Transparency Layer, etc.)
- **task**: Implementation units of work
- **feature**: User-facing feature requests
- **bug**: Defects and issues

## Issue ID Format
`stonkwatch-app-xxxxx` (5 char random suffix)

## Current Epics

1. **Living Briefing System** - Continuous AI updates, not point-in-time
2. **Confidence Decay Visual System** - Older info fades, new info pulses
3. **Explainable AI Transparency** - Sources inline with "why this matters"
4. **Predictive Action Suggestions** - AI recommends next steps
5. **Highlight + Ask Interaction** - Contextual questioning
6. **Portfolio Correlation Engine** - Cross-reference with user's positions
7. **Voice-First Interface** - Audio briefings and queries

## Commands

```bash
# List all open issues
beads ls

# Show epic with children
beads show stonkwatch-app-xxxxx

# Create new task
beads create --type task --title "Task name" --parent stonkwatch-app-xxxxx
```
