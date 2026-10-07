# Improvements

## End-to-end test for the hooks

Banked: an end-to-end test that runs each hook through claude-code.

To actually exercise `post-tool-use` and test whether claude-code picks up the
hooks as expected, an end-to-end test exercising each hook would be perfect. To
achieve this, I believe we need a logged-in user. Until I can get around this
problem, I want to bank this test and call it out here.
