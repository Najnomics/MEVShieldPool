/**
 * Avail Nexus Integration Entry Point
 * Cross-chain MEV protection demonstration using Avail Nexus SDK
 * 
 * This demo showcases:
 * - Cross-chain MEV detection and protection
 * - Bridge & Execute functionality for arbitrage
 * - Unified balance management across chains
 * - Intent-based transaction execution
 * - Real-time cross-chain monitoring
 * 
 * Built for ETHOnline 2025 - Avail $10,000 Best DeFi app with Avail Nexus SDK
 * Author: MEVShield Pool Team
 */

import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';
import AvailNexusIntegration from './AvailNexusIntegration.js';
import CrossChainMEVProtection from './CrossChainMEVProtection.js';

// Load environment variables
dotenv.config();

class AvailMEVShieldDemo {
    constructor() {
        this.app = express();
        this.server = createServer(this.app);
        this.io = new Server(this.server, {
            cors: {
                origin: process.env.FRONTEND_URL || "http://localhost:3000",
                methods: ["GET", "POST"]
            }
        });
        
        this.port = process.env.AVAIL_PORT || 3002;
        
        // Core components
        this.availIntegration = null;
        this.mevProtection = null;
        
        // Demo state
        this.connectedUsers = new Map();
        this.demoStats = {
            totalUsers: 0,
            totalCrossChainTxs: 0,
            totalMEVSaved: 0,
            averageExecutionTime: 0,
            supportedChains: 8
        };
        
        this.isRunning = false;
    }

    async initialize() {
        try {
            console.log('🚀 Initializing Avail MEVShield Demo...');
            
            // Initialize Avail Nexus Integration
            await this.initializeAvailIntegration();
            
            // Setup Express middleware and routes
            this.setupExpressApp();
            
            // Setup WebSocket handlers
            this.setupWebSocketHandlers();
            
            // Start demo monitoring
            this.startDemoMonitoring();
            
            console.log('✅ Avail MEVShield Demo initialized successfully');
            
        } catch (error) {
            console.error('❌ Demo initialization failed:', error);
            throw error;
        }
    }

    async initializeAvailIntegration() {
        try {
            // Initialize Avail Nexus Integration with demo configuration
            this.availIntegration = new AvailNexusIntegration({
                supportedChains: [
                    'ethereum',
                    'polygon',
                    'arbitrum',
                    'optimism', 
                    'base',
                    'avalanche',
                    'fantom',
                    'bsc'
                ],
                mevDetectionThreshold: 0.002, // 0.2% for demo sensitivity
                maxBridgeFee: '0.005', // 0.005 ETH max bridge fee
                rebalanceInterval: 60000, // 1 minute for demo
                opportunityWindow: 45000 // 45 seconds
            });

            await this.availIntegration.initialize({
                autoExecuteMEV: true, // Enable auto-execution for demo
                demoMode: true
            });

            console.log('🔧 Avail Nexus Integration initialized');

            // Setup integration event listeners
            this.setupIntegrationEventListeners();

        } catch (error) {
            console.error('❌ Avail integration initialization failed:', error);
            throw error;
        }
    }

    setupExpressApp() {
        // CORS and JSON middleware
        this.app.use(cors({
            origin: process.env.FRONTEND_URL || "http://localhost:3000",
            credentials: true
        }));
        
        this.app.use(express.json({ limit: '10mb' }));
        
        // Health check endpoint
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                integration: 'avail-nexus',
                version: '1.0.0'
            });
        });

        // Avail integration metadata
        this.app.get('/avail/metadata', (req, res) => {
            res.json({
                name: 'MEVShield Cross-Chain Protection',
                description: 'Cross-chain MEV protection using Avail Nexus SDK',
                supportedChains: this.availIntegration?.config?.supportedChains || [],
                features: [
                    'Cross-chain MEV detection',
                    'Bridge & Execute arbitrage',
                    'Unified balance management',
                    'Intent-based execution',
                    'Real-time monitoring'
                ],
                stats: this.demoStats
            });
        });

        // Connect user endpoint
        this.app.post('/avail/connect', async (req, res) => {
            try {
                const { walletAddress, chainId } = req.body;
                
                if (!walletAddress || !chainId) {
                    return res.status(400).json({
                        error: 'Missing walletAddress or chainId'
                    });
                }

                const result = await this.availIntegration.connectUser(walletAddress, chainId);
                
                // Track connected user
                this.connectedUsers.set(walletAddress, {
                    address: walletAddress,
                    chainId: chainId,
                    connectedAt: Date.now()
                });
                
                this.demoStats.totalUsers = this.connectedUsers.size;

                res.json(result);

            } catch (error) {
                console.error('❌ User connection error:', error);
                res.status(500).json({
                    error: 'Connection failed',
                    message: error.message
                });
            }
        });

        // Get user balances
        this.app.get('/avail/balances/:address', async (req, res) => {
            try {
                const { address } = req.params;
                
                if (!this.connectedUsers.has(address)) {
                    return res.status(404).json({
                        error: 'User not connected'
                    });
                }

                const balances = await this.availIntegration.getUserBalances();
                res.json(balances);

            } catch (error) {
                console.error('❌ Balance fetch error:', error);
                res.status(500).json({
                    error: 'Failed to fetch balances',
                    message: error.message
                });
            }
        });

        // Execute cross-chain intent
        this.app.post('/avail/intent', async (req, res) => {
            try {
                const intentConfig = req.body;
                
                if (!intentConfig.sourceChain || !intentConfig.targetChain) {
                    return res.status(400).json({
                        error: 'Missing required intent parameters'
                    });
                }

                const result = await this.availIntegration.executeCrossChainIntent(intentConfig);
                res.json(result);

            } catch (error) {
                console.error('❌ Intent execution error:', error);
                res.status(500).json({
                    error: 'Intent execution failed',
                    message: error.message
                });
            }
        });

        // Get active intents
        this.app.get('/avail/intents/:address', async (req, res) => {
            try {
                const { address } = req.params;
                
                if (!this.connectedUsers.has(address)) {
                    return res.status(404).json({
                        error: 'User not connected'
                    });
                }

                const intents = await this.availIntegration.getActiveIntents();
                res.json(intents);

            } catch (error) {
                console.error('❌ Intents fetch error:', error);
                res.status(500).json({
                    error: 'Failed to fetch intents',
                    message: error.message
                });
            }
        });

        // Get integration stats
        this.app.get('/avail/stats', (req, res) => {
            const integrationStats = this.availIntegration?.getStats() || {};
            
            res.json({
                ...this.demoStats,
                ...integrationStats,
                timestamp: new Date().toISOString()
            });
        });

        // Demo endpoints for testing
        this.app.post('/avail/demo/trigger-arbitrage', async (req, res) => {
            try {
                // Simulate arbitrage opportunity for demo
                const opportunity = {
                    sourceChain: 'ethereum',
                    targetChain: 'polygon',
                    pair: 'ETH/USDC',
                    amount: '0.1',
                    estimatedProfit: 0.005,
                    confidence: 0.85
                };

                const result = await this.availIntegration.executeArbitrageIntent(opportunity);
                res.json(result);

            } catch (error) {
                console.error('❌ Demo arbitrage error:', error);
                res.status(500).json({
                    error: 'Demo arbitrage failed',
                    message: error.message
                });
            }
        });

        this.app.post('/avail/demo/trigger-rebalance', async (req, res) => {
            try {
                // Simulate rebalancing for demo
                const rebalanceConfig = {
                    fromChain: 'ethereum',
                    toChain: 'arbitrum',
                    amount: '0.05',
                    targetAllocation: {
                        ethereum: 0.4,
                        polygon: 0.2,
                        arbitrum: 0.3,
                        optimism: 0.1
                    }
                };

                const result = await this.availIntegration.executeRebalanceIntent(rebalanceConfig);
                res.json(result);

            } catch (error) {
                console.error('❌ Demo rebalance error:', error);
                res.status(500).json({
                    error: 'Demo rebalance failed',
                    message: error.message
                });
            }
        });

        // Error handling middleware
        this.app.use((error, req, res, next) => {
            console.error('API Error:', error);
            res.status(500).json({
                error: 'Internal server error',
                message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
            });
        });
    }

    setupWebSocketHandlers() {
        this.io.on('connection', (socket) => {
            console.log(`🔌 Client connected: ${socket.id}`);

            // Subscribe to cross-chain updates
            socket.on('subscribe_crosschain', (data) => {
                const { userAddress } = data;
                socket.join(`crosschain_${userAddress}`);
                console.log(`📡 Client subscribed to cross-chain updates for ${userAddress}`);
            });

            // Subscribe to MEV alerts  
            socket.on('subscribe_mev_alerts', (data) => {
                const { userAddress } = data;
                socket.join(`mev_alerts_${userAddress}`);
                console.log(`🛡️ Client subscribed to MEV alerts for ${userAddress}`);
            });

            // Subscribe to real-time stats
            socket.on('subscribe_stats', () => {
                socket.join('demo_stats');
                console.log(`📊 Client subscribed to demo stats`);
            });

            socket.on('disconnect', (reason) => {
                console.log(`🔌 Client disconnected: ${socket.id} - ${reason}`);
            });
        });
    }

    setupIntegrationEventListeners() {
        // Listen for MEV opportunities
        this.availIntegration.mevProtection?.on('mevOpportunitiesDetected', (event) => {
            console.log(`🔍 MEV opportunities detected: ${event.opportunities.length}`);
            
            // Broadcast to subscribed clients
            this.io.to('demo_stats').emit('mev_opportunities', {
                opportunities: event.opportunities,
                timestamp: event.timestamp
            });
        });

        // Listen for arbitrage executions
        this.availIntegration.mevProtection?.on('arbitrageExecuted', (event) => {
            console.log(`⚡ Arbitrage executed: ${event.intent.id}`);
            
            // Update demo stats
            this.demoStats.totalMEVSaved += event.intent.expectedProfit;
            this.demoStats.totalCrossChainTxs++;
            
            // Broadcast to relevant user
            if (event.intent.user) {
                this.io.to(`crosschain_${event.intent.user}`).emit('arbitrage_executed', {
                    intent: event.intent,
                    result: event.result,
                    timestamp: event.timestamp
                });
            }
        });

        // Listen for intent completions
        this.availIntegration.mevProtection?.on('intentCompleted', (event) => {
            console.log(`✅ Intent completed: ${event.intent.id}`);
            
            // Update execution time stats
            if (event.intent.executionDuration) {
                const currentAvg = this.demoStats.averageExecutionTime;
                const totalTxs = this.demoStats.totalCrossChainTxs;
                this.demoStats.averageExecutionTime = 
                    (currentAvg * (totalTxs - 1) + event.intent.executionDuration) / totalTxs;
            }
            
            // Broadcast completion
            if (event.intent.user) {
                this.io.to(`crosschain_${event.intent.user}`).emit('intent_completed', {
                    intent: event.intent,
                    timestamp: event.timestamp
                });
            }
        });
    }

    startDemoMonitoring() {
        // Update demo stats every 10 seconds
        setInterval(() => {
            this.updateDemoStats();
        }, 10000);

        // Broadcast stats to connected clients every 5 seconds
        setInterval(() => {
            this.broadcastStats();
        }, 5000);

        console.log('📊 Demo monitoring started');
    }

    updateDemoStats() {
        if (this.availIntegration) {
            const integrationStats = this.availIntegration.getStats();
            
            // Update cumulative stats
            this.demoStats.totalCrossChainTxs = integrationStats.totalBridges || 0;
            this.demoStats.totalMEVSaved = integrationStats.totalMEVCaptured || 0;
            this.demoStats.averageExecutionTime = integrationStats.averageExecutionTime || 0;
        }
    }

    broadcastStats() {
        const currentStats = {
            ...this.demoStats,
            timestamp: new Date().toISOString(),
            connectedUsers: this.connectedUsers.size
        };

        this.io.to('demo_stats').emit('stats_update', currentStats);
    }

    async start() {
        try {
            await this.initialize();
            
            this.server.listen(this.port, () => {
                console.log(`🎯 Avail MEVShield Demo running on port ${this.port}`);
                console.log(`📊 Demo Dashboard: http://localhost:${this.port}`);
                console.log(`🔧 Health Check: http://localhost:${this.port}/health`);
                console.log(`📋 Metadata: http://localhost:${this.port}/avail/metadata`);
            });
            
            this.isRunning = true;
            
            // Graceful shutdown handling
            process.on('SIGINT', () => this.shutdown('SIGINT'));
            process.on('SIGTERM', () => this.shutdown('SIGTERM'));
            
        } catch (error) {
            console.error('❌ Failed to start Avail MEVShield Demo:', error);
            process.exit(1);
        }
    }

    async shutdown(signal) {
        console.log(`\n🛑 Received ${signal}, shutting down demo...`);
        
        try {
            this.isRunning = false;
            
            // Disconnect all users
            for (const userAddress of this.connectedUsers.keys()) {
                // Notify user of shutdown
                this.io.to(`crosschain_${userAddress}`).emit('demo_shutdown', {
                    message: 'Demo is shutting down',
                    timestamp: new Date().toISOString()
                });
            }
            
            // Stop Avail integration
            if (this.availIntegration) {
                await this.availIntegration.disconnect();
            }
            
            // Close WebSocket connections
            this.io.close();
            
            // Close HTTP server
            this.server.close(() => {
                console.log('🔌 HTTP server closed');
            });
            
            console.log('✅ Demo shutdown completed');
            process.exit(0);
            
        } catch (error) {
            console.error('❌ Error during shutdown:', error);
            process.exit(1);
        }
    }
}

// Create and start the demo
const demo = new AvailMEVShieldDemo();
demo.start().catch(error => {
    console.error('❌ Fatal error starting demo:', error);
    process.exit(1);
});

export default AvailMEVShieldDemo;