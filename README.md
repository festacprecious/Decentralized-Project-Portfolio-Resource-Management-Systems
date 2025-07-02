# Decentralized Project Portfolio Resource Management System

A blockchain-based system for managing project portfolios, resource allocation, and performance tracking using Clarity smart contracts.

## Overview

This system provides a decentralized approach to project portfolio management with the following core components:

- **Portfolio Coordinator Verification**: Validates and manages portfolio coordinators
- **Resource Allocation**: Manages and distributes portfolio resources
- **Priority Management**: Handles project prioritization and scheduling
- **Performance Tracking**: Monitors and records portfolio performance metrics
- **Optimization Planning**: Provides portfolio optimization strategies

## Features

### Portfolio Coordinator Verification
- Coordinator registration and verification
- Role-based access control
- Reputation tracking
- Multi-signature approval for critical operations

### Resource Allocation
- Dynamic resource distribution
- Budget management
- Resource conflict resolution
- Automated allocation based on priorities

### Priority Management
- Project priority scoring
- Dynamic priority adjustment
- Deadline management
- Resource-priority correlation

### Performance Tracking
- Real-time performance metrics
- Historical data storage
- Performance benchmarking
- Automated reporting

### Optimization Planning
- Resource optimization algorithms
- Performance-based recommendations
- Risk assessment
- Strategic planning tools

## Architecture

The system consists of five interconnected Clarity smart contracts:

1. \`portfolio-coordinator.clar\` - Manages coordinator verification and roles
2. \`resource-allocation.clar\` - Handles resource distribution and budgeting
3. \`priority-management.clar\` - Manages project priorities and scheduling
4. \`performance-tracking.clar\` - Tracks and stores performance metrics
5. \`optimization-planning.clar\` - Provides optimization strategies

## Getting Started

### Prerequisites
- Stacks blockchain environment
- Clarity development tools
- Node.js for testing

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts to testnet/mainnet

### Usage

#### Registering as a Portfolio Coordinator
\`\`\`clarity
(contract-call? .portfolio-coordinator register-coordinator "coordinator-name" "expertise-area")
\`\`\`

#### Allocating Resources
\`\`\`clarity
(contract-call? .resource-allocation allocate-resources project-id resource-amount)
\`\`\`

#### Setting Project Priorities
\`\`\`clarity
(contract-call? .priority-management set-priority project-id priority-score)
\`\`\`

#### Tracking Performance
\`\`\`clarity
(contract-call? .performance-tracking record-performance project-id metrics)
\`\`\`

## Testing

The system includes comprehensive tests using Vitest:

\`\`\`bash
npm test
\`\`\`

Tests cover:
- Coordinator verification workflows
- Resource allocation scenarios
- Priority management operations
- Performance tracking accuracy
- Optimization planning algorithms

## Security Considerations

- Multi-signature requirements for critical operations
- Role-based access control
- Input validation and sanitization
- Reentrancy protection
- Emergency pause functionality

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## License

MIT License - see LICENSE file for details
