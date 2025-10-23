/**
 * MEVShield Vincent App - Main Entry Point
 * Automated MEV Protection and Yield Optimization for Uniswap V4
 * 
 * This Vincent app provides:
 * - Automated MEV auction bidding
 * - Cross-chain arbitrage detection
 * - Yield optimization strategies
 * - Real-time risk management
 * 
 * Built for ETHOnline 2025 - Lit Protocol Prize
 * Author: MEVShield Pool Team
 */

import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { MongoClient } from 'mongodb';
import { createServer } from 'http';
import { Server } from 'socket.io';

// Vincent App Components
import { VincentAuthManager } from './auth/VincentAuthManager.js';
import { MEVAutomationEngine } from './automation/MEVAutomationEngine.js';
import { PolicyManager } from './policies/PolicyManager.js';
import { AbilityRegistry } from './abilities/AbilityRegistry.js';
import { DashboardService } from './services/DashboardService.js';

// API Routes
import authRoutes from './routes/auth.js';
import automationRoutes from './routes/automation.js';
import policiesRoutes from './routes/policies.js';
import abilitiesRoutes from './routes/abilities.js';
import dashboardRoutes from './routes/dashboard.js';

// Load environment variables
dotenv.config();

class MEVShieldVincentApp {
    constructor() {
        this.app = express();
        this.server = createServer(this.app);
        this.io = new Server(this.server, {
            cors: {
                origin: process.env.FRONTEND_URL || "http://localhost:3000",
                methods: ["GET", "POST"]
            }
        });
        
        this.port = process.env.PORT || 3001;
        this.mongoClient = null;
        this.database = null;
        
        // Core components
        this.authManager = null;
        this.automationEngine = null;
        this.policyManager = null;
        this.abilityRegistry = null;
        this.dashboardService = null;
        
        this.isInitialized = false;
    }

    async initialize() {
        try {
            console.log('🚀 Initializing MEVShield Vincent App...');
            
            // Connect to MongoDB
            await this.connectDatabase();
            
            // Initialize core components
            await this.initializeComponents();
            
            // Setup Express middleware
            this.setupMiddleware();
            
            // Setup routes
            this.setupRoutes();
            
            // Setup WebSocket handlers
            this.setupWebSocketHandlers();
            
            this.isInitialized = true;
            console.log('✅ MEVShield Vincent App initialized successfully');
            
        } catch (error) {
            console.error('❌ Failed to initialize Vincent App:', error);
            throw error;
        }
    }

    async connectDatabase() {
        try {
            const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/mevshield-vincent';
            this.mongoClient = new MongoClient(mongoUri);
            await this.mongoClient.connect();
            
            const dbName = process.env.MONGODB_DB_NAME || 'mevshield-vincent';
            this.database = this.mongoClient.db(dbName);
            
            console.log('📦 Connected to MongoDB database:', dbName);
            
            // Create indexes for performance
            await this.createDatabaseIndexes();
            
        } catch (error) {
            console.error('❌ Database connection failed:', error);
            throw error;
        }
    }

    async createDatabaseIndexes() {
        try {
            // Users collection indexes
            await this.database.collection('users').createIndex({ 'wallet_address': 1 }, { unique: true });
            await this.database.collection('users').createIndex({ 'email': 1 }, { unique: true, sparse: true });
            
            // Automation sessions indexes
            await this.database.collection('automation_sessions').createIndex({ 'user_id': 1 });
            await this.database.collection('automation_sessions').createIndex({ 'created_at': 1 });
            await this.database.collection('automation_sessions').createIndex({ 'status': 1 });
            
            // MEV opportunities indexes
            await this.database.collection('mev_opportunities').createIndex({ 'pool_id': 1 });
            await this.database.collection('mev_opportunities').createIndex({ 'detected_at': 1 });
            await this.database.collection('mev_opportunities').createIndex({ 'risk_score': 1 });
            
            // Policies indexes
            await this.database.collection('policies').createIndex({ 'user_id': 1 });
            await this.database.collection('policies').createIndex({ 'ability_name': 1 });
            
            console.log('📇 Database indexes created successfully');
            
        } catch (error) {
            console.error('⚠️  Warning: Failed to create database indexes:', error);
        }
    }

    async initializeComponents() {
        try {
            // Initialize authentication manager
            this.authManager = new VincentAuthManager(this.database);
            await this.authManager.initialize();
            
            // Initialize policy manager
            this.policyManager = new PolicyManager(this.database);
            await this.policyManager.initialize();
            
            // Initialize ability registry
            this.abilityRegistry = new AbilityRegistry(this.database);
            await this.abilityRegistry.initialize();
            
            // Initialize automation engine
            this.automationEngine = new MEVAutomationEngine(
                this.database,
                this.policyManager,
                this.abilityRegistry,
                this.io
            );
            await this.automationEngine.initialize();
            
            // Initialize dashboard service
            this.dashboardService = new DashboardService(
                this.database,
                this.automationEngine,
                this.io
            );
            await this.dashboardService.initialize();
            
            console.log('🔧 Core components initialized successfully');
            
        } catch (error) {
            console.error('❌ Component initialization failed:', error);
            throw error;
        }
    }

    setupMiddleware() {
        // CORS
        this.app.use(cors({
            origin: process.env.FRONTEND_URL || "http://localhost:3000",
            credentials: true
        }));
        
        // JSON parsing
        this.app.use(express.json({ limit: '10mb' }));
        this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));
        
        // Request logging
        this.app.use((req, res, next) => {
            console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
            next();
        });
        
        // Health check endpoint
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                version: process.env.npm_package_version || '1.0.0',
                initialized: this.isInitialized
            });
        });
        
        // Vincent app metadata endpoint
        this.app.get('/vincent/metadata', (req, res) => {
            res.json({
                name: process.env.VINCENT_APP_NAME || 'MEVShield Pool Automation',
                description: process.env.VINCENT_APP_DESCRIPTION || 'Automated MEV protection and yield optimization',
                version: '1.0.0',
                abilities: this.abilityRegistry ? this.abilityRegistry.getAvailableAbilities() : [],
                author: 'MEVShield Pool Team',
                website: 'https://github.com/najnomics/mevshield-pool',
                logo: '/assets/logo.png'
            });
        });
    }

    setupRoutes() {
        // API Routes
        this.app.use('/api/auth', authRoutes(this.authManager));
        this.app.use('/api/automation', automationRoutes(this.automationEngine));
        this.app.use('/api/policies', policiesRoutes(this.policyManager));
        this.app.use('/api/abilities', abilitiesRoutes(this.abilityRegistry));
        this.app.use('/api/dashboard', dashboardRoutes(this.dashboardService));
        
        // Vincent callback endpoint
        this.app.get('/auth/callback', async (req, res) => {
            try {
                const { code, state } = req.query;
                const result = await this.authManager.handleVincentCallback(code, state);
                
                if (result.success) {
                    res.redirect(`${process.env.FRONTEND_URL}/dashboard?auth=success`);
                } else {
                    res.redirect(`${process.env.FRONTEND_URL}/auth?error=${encodeURIComponent(result.error)}`);
                }
            } catch (error) {
                console.error('Vincent callback error:', error);
                res.redirect(`${process.env.FRONTEND_URL}/auth?error=callback_failed`);
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
        
        // 404 handler
        this.app.use('*', (req, res) => {
            res.status(404).json({
                error: 'Not found',
                message: `Route ${req.originalUrl} not found`
            });
        });
    }

    setupWebSocketHandlers() {
        this.io.on('connection', (socket) => {
            console.log(`🔌 New client connected: ${socket.id}`);
            
            socket.on('subscribe_mev_alerts', (data) => {
                const { userId, poolIds } = data;
                socket.join(`mev_alerts_${userId}`);
                
                if (poolIds && Array.isArray(poolIds)) {
                    poolIds.forEach(poolId => {
                        socket.join(`pool_${poolId}`);
                    });
                }
                
                console.log(`📡 Client ${socket.id} subscribed to MEV alerts for user ${userId}`);
            });
            
            socket.on('subscribe_automation_updates', (data) => {
                const { userId, sessionId } = data;
                socket.join(`automation_${userId}`);
                
                if (sessionId) {
                    socket.join(`session_${sessionId}`);
                }
                
                console.log(`🤖 Client ${socket.id} subscribed to automation updates`);
            });
            
            socket.on('unsubscribe_all', () => {
                socket.leaveAll();
                console.log(`📴 Client ${socket.id} unsubscribed from all channels`);
            });
            
            socket.on('disconnect', (reason) => {
                console.log(`🔌 Client disconnected: ${socket.id} - ${reason}`);
            });
        });
    }

    async start() {
        try {
            await this.initialize();
            
            this.server.listen(this.port, () => {
                console.log(`🎯 MEVShield Vincent App running on port ${this.port}`);
                console.log(`📊 Dashboard: http://localhost:${this.port}`);
                console.log(`🔧 Health Check: http://localhost:${this.port}/health`);
                console.log(`📋 Vincent Metadata: http://localhost:${this.port}/vincent/metadata`);
            });
            
            // Graceful shutdown handling
            process.on('SIGINT', () => this.shutdown('SIGINT'));
            process.on('SIGTERM', () => this.shutdown('SIGTERM'));
            
        } catch (error) {
            console.error('❌ Failed to start Vincent App:', error);
            process.exit(1);
        }
    }

    async shutdown(signal) {
        console.log(`\n🛑 Received ${signal}, starting graceful shutdown...`);
        
        try {
            // Stop automation engine
            if (this.automationEngine) {
                await this.automationEngine.stop();
            }
            
            // Close WebSocket connections
            this.io.close();
            
            // Close HTTP server
            this.server.close(() => {
                console.log('🔌 HTTP server closed');
            });
            
            // Close database connection
            if (this.mongoClient) {
                await this.mongoClient.close();
                console.log('📦 Database connection closed');
            }
            
            console.log('✅ Graceful shutdown completed');
            process.exit(0);
            
        } catch (error) {
            console.error('❌ Error during shutdown:', error);
            process.exit(1);
        }
    }
}

// Create and start the Vincent app
const vincentApp = new MEVShieldVincentApp();
vincentApp.start().catch(error => {
    console.error('❌ Fatal error starting Vincent App:', error);
    process.exit(1);
});

export default MEVShieldVincentApp;