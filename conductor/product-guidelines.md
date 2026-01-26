# Product Guidelines: Unikey for macOS

## Design Philosophy
- **Native & Seamless:** The application should feel like an extension of macOS. Use standard system components, fonts, and interaction patterns.
- **Reliability First:** As an input method, the app must be rock-solid. Functional correctness in character transformation and event handling is paramount.

## User Experience (UX)
- **Helpful Onboarding:** Since the app requires sensitive Accessibility permissions, provide a friendly and clear onboarding experience to guide users through the setup.
- **Frictionless Interaction:** Most interaction happens via the keyboard. UI elements (menus, preferences) should be clean, efficient, and never interrupt the user's primary task (typing).

## Visual Identity
- **macOS HIG Adherence:** Strictly follow Apple's Human Interface Guidelines. Use standard SF Pro fonts, system colors, and native controls.
- **Menu Bar Presence:** The menu bar icon should be distinct but unobtrusive, clearly indicating the current input state (e.g., 'V' for Vietnamese, 'E' for English).

## Tone & Voice
- **Helpful & Approachable:** Use friendly language that demystifies technical requirements. Avoid jargon unless necessary, and provide context where users might be confused.
- **Clear & Functional:** Instructions and labels should be direct and unambiguous to ensure users can configure the app quickly and correctly.

## Error Handling & Permissions
- **Proactive Guidance:** Missing permissions should be treated as a primary user flow. Use clear, step-by-step instructions to help users grant the necessary access.
- **Graceful Degradation:** If a feature fails, inform the user clearly and provide actionable steps to resolve the issue.
