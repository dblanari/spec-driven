Solution1: Use CustomGPT and MCP server(GitHub) as repository to store and manage ADRs.
Create a system that leverages CustomGPT for drafting and validating Architecture Decision Records (ADRs) while using an MCP server (GitHub) as the repository for storing and managing ADRs.
The system will consist of the following components:
CustomGPT Integration: Utilize CustomGPT to draft ADRs based on user-provided context, constraints, and options, ensuring adherence to the official ADR template.
MCP Server (GitHub):
Use Default CustomGPT interface to connect to a GitHub repository that serves as the MCP server for storing ADRs.