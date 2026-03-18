
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('./database.js');
const authenticateToken = require('./auth.js');
const crypto = require('crypto');
const axios = require('axios');
const cloudinary = require('cloudinary').v2;

cloudinary.config({
    cloud_name: process.env.CLOUD_NAME,
    api_key: process.env.CLOUD_API_KEY,
    api_secret: process.env.CLOUD_API_SECRET
});

const router = express.Router();

// Register new user account
router.post('/register', async (req, res) => {
    try {
        const { email, username, password } = req.body;
        
        if (!email || !username || !password) {
            return res.status(400).json({ error: "Please fill in all fields" });
        }
        
        const existingUser = await db.query(
            'SELECT * FROM users WHERE email = $1 OR username = $2',
            [email, username]
        );
        
        if (existingUser.rows.length > 0) {
            const existing = existingUser.rows[0];
            if (existing.email === email) {
                return res.status(409).json({ error: "An account with this email already exists" });
            }
            if (existing.username === username) {
                return res.status(409).json({ error: "This username is already taken" });
            }
        }
        
        const password_hash = await bcrypt.hash(password, 10);
        
        const user = await db.query(
            'INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3) RETURNING id, username, email, created_at',
            [username, email, password_hash]
        );
        
        res.status(201).json({
            message: "Welcome to CROPTECH! Your account has been created successfully.",
            user: user.rows[0]
        });
        
    } catch (error) {
        console.log(error);
        res.status(500).json({ error: "Something went wrong. Please try again later." });
    }
});

// Login user and return JWT token
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        if (!email || !password) {
            return res.status(400).json({ error: "Please enter both email and password" });
        }
        
        const userSearch = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        
        if (userSearch.rows.length === 0) {
            return res.status(401).json({ error: "Invalid email or password" });
        }
        
        const user = userSearch.rows[0];
        const passwordValid = await bcrypt.compare(password, user.password_hash);
        
        if (!passwordValid) {
            return res.status(401).json({ error: "Invalid email or password" });
        }
        
        const token = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );
        
        res.status(200).json({
            message: "Welcome back! Login successful.",
            token: token,
            user: { id: user.id, username: user.username, email: user.email }
        });
        
    } catch (error) {
        console.error("Login error:", error);
        res.status(500).json({ error: "Unable to log in. Please try again." });
    }
});

// Logout user (client-side token removal)
router.post('/logout', authenticateToken, (req, res) => {
    res.json({ message: "You have been logged out successfully" });
});

// Change password for authenticated user
router.post('/change-password', authenticateToken, async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        const userId = req.user.userId;
        
        if (!currentPassword || !newPassword) {
            return res.status(400).json({ error: "Please enter both current and new password" });
        }
        
        if (newPassword.length < 6) {
            return res.status(400).json({ error: "New password must be at least 6 characters long" });
        }
        
        const userResult = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
        
        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: "User not found" });
        }
        
        const user = userResult.rows[0];
        const validPassword = await bcrypt.compare(currentPassword, user.password_hash);
        
        if (!validPassword) {
            return res.status(401).json({ error: "Current password is incorrect" });
        }
        
        const newPassHash = await bcrypt.hash(newPassword, 10);
        
        await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [newPassHash, userId]);
        
        res.json({ message: "Password changed successfully" });
        
    } catch (error) {
        console.log(error);
        res.status(500).json({ error: "Unable to change password" });
    }
});

// Request password reset email with token
router.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({ error: "Please enter your email address" });
        }
        
        const userResult = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        
        if (userResult.rows.length === 0) {
            return res.json({ message: "If an account exists with this email, you will receive password reset instructions." });
        }
        
        const user = userResult.rows[0];
        const resetToken = crypto.randomBytes(32).toString('hex');
        const tokenExpiry = new Date(Date.now() + 3600000);
        
        await db.query(
            'UPDATE users SET reset_token = $1, reset_token_expiry = $2 WHERE id = $3',
            [resetToken, tokenExpiry, user.id]
        );
        
        res.json({ 
            message: "If an account exists with this email, you will receive password reset instructions.",
            resetLink: `http://localhost:3000/reset-password/${resetToken}`,
            token: resetToken
        });
        
    } catch (error) {
        console.log("Forgot password error:", error);
        res.status(500).json({ error: "Unable to process request. Please try again." });
    }
});

// Reset password using valid token
router.post('/reset-password', async (req, res) => {
    try {
        const { token, newPassword } = req.body;
        
        if (!token || !newPassword) {
            return res.status(400).json({ error: "Token and new password are required" });
        }
        
        if (newPassword.length < 6) {
            return res.status(400).json({ error: "Password must be at least 6 characters long" });
        }
        
        const userResult = await db.query('SELECT * FROM users WHERE reset_token = $1', [token]);
        
        if (userResult.rows.length === 0) {
            return res.status(400).json({ error: "Invalid or expired reset token" });
        }
        
        const user = userResult.rows[0];
        
        if (user.reset_token_expiry < new Date()) {
            return res.status(400).json({ error: "Reset token has expired" });
        }
        
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        
        await db.query(
            'UPDATE users SET password_hash = $1, reset_token = NULL, reset_token_expiry = NULL WHERE id = $2',
            [hashedPassword, user.id]
        );
        
        res.json({ message: "Password has been reset successfully. You can now login with your new password." });
        
    } catch (error) {
        console.log("Reset password error:", error);
        res.status(500).json({ error: "Server error. Please try again." });
    }
});

// Get authenticated user's profile information
router.get('/profile', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const userData = await db.query(
            'SELECT id, username, email, created_at FROM users WHERE id = $1',
            [userId]
        );
        
        if (userData.rows.length === 0) {
            return res.status(404).json({ error: "User profile not found" });
        }
        
        res.json({
            message: "Profile retrieved successfully",
            user: userData.rows[0]
        });
        
    } catch (error) {
        console.log("Error fetching profile:", error);
        res.status(500).json({ error: "Unable to fetch profile" });
    }
});

// Get dashboard statistics for authenticated user
router.get('/dashboard/stats', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const totalScans = await db.query('SELECT COUNT(*) FROM detections WHERE user_id = $1', [userId]);
        const lastWeekScans = await db.query('SELECT COUNT(*) FROM detections WHERE user_id = $1 AND created_at >= NOW() - INTERVAL \'7 days\'', [userId]);
        const previousWeekScans = await db.query('SELECT COUNT(*) FROM detections WHERE user_id = $1 AND created_at >= NOW() - INTERVAL \'14 days\' AND created_at < NOW() - INTERVAL \'7 days\'', [userId]);
        const issues = await db.query('SELECT COUNT(*) FROM detections WHERE user_id = $1 AND confidence < 80', [userId]);
        const healthy = await db.query(
            `SELECT COUNT(*) FROM detections d JOIN diseases dis ON d.disease_id = dis.id WHERE d.user_id = $1 AND LOWER(dis.name) LIKE '%healthy%'`,
            [userId]
        );
        
        const previousCount = parseInt(previousWeekScans.rows[0].count) || 1;
        const currentCount = parseInt(lastWeekScans.rows[0].count);
        const percentChange = Math.round(((currentCount - previousCount) / previousCount) * 100);
        
        res.json({
            totalScans: parseInt(totalScans.rows[0].count),
            scansChange: `${percentChange > 0 ? '+' : ''}${percentChange}%`,
            issuesDetected: parseInt(issues.rows[0].count),
            healthyCrops: parseInt(healthy.rows[0].count),
            period: "last week"
        });
        
    } catch (error) {
        console.log("Dashboard stats error:", error);
        res.status(500).json({ error: "Unable to fetch dashboard stats" });
    }
});

// Get all diseases with optional search by name or crop
router.get('/diseases', async (req, res) => {
    try {
        const { query, crop } = req.query;
        
        let sql = 'SELECT * FROM diseases';
        const params = [];
        const conditions = [];
        
        if (query) {
            conditions.push(`(name ILIKE $${params.length + 1} OR description ILIKE $${params.length + 1})`);
            params.push(`%${query}%`);
        }
        
        if (crop) {
            conditions.push(`crop ILIKE $${params.length + 1}`);
            params.push(`%${crop}%`);
        }
        
        if (conditions.length > 0) {
            sql += ' WHERE ' + conditions.join(' AND ');
        }
        
        sql += ' ORDER BY name';
        
        const diseases = await db.query(sql, params);
        
        res.json({
            message: "Diseases retrieved successfully",
            count: diseases.rows.length,
            diseases: diseases.rows.map(d => ({
                id: d.id,
                name: d.name,
                crop: d.crop || "General",
                description: d.description,
                symptoms: d.symptoms,
                treatment: d.treatment,
                prevention: d.prevention,
                imageUrl: d.image_url || null
            }))
        });
        
    } catch (error) {
        console.log("Diseases error:", error);
        res.status(500).json({ error: "Unable to fetch diseases" });
    }
});

// Get specific disease by ID
router.get('/diseases/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const disease = await db.query('SELECT * FROM diseases WHERE id = $1', [id]);
        
        if (disease.rows.length === 0) {
            return res.status(404).json({ error: "Disease not found" });
        }
        
        res.json({
            message: "Disease retrieved successfully",
            disease: {
                id: disease.rows[0].id,
                name: disease.rows[0].name,
                crop: disease.rows[0].crop || "General",
                description: disease.rows[0].description,
                symptoms: disease.rows[0].symptoms,
                treatment: disease.rows[0].treatment,
                prevention: disease.rows[0].prevention,
                imageUrl: disease.rows[0].image_url || null
            }
        });
        
    } catch (error) {
        console.log(error);
        res.status(500).json({ error: "Unable to fetch disease" });
    }
});

// Call AI model for disease detection
async function callAIModel(imageBase64) {
    const aiServiceUrl = process.env.AI_MODEL_URL || 'http://localhost:5000/predict';
    
    const response = await axios.post(aiServiceUrl, {
        image: imageBase64
    }, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000
    });
    
    return {
        name: response.data.disease || response.data.name || response.data.prediction,
        confidence: response.data.confidence || response.data.score || response.data.probability,
        crop: response.data.crop || "Unknown"
    };
}

// Submit crop image for AI disease detection and analysis
router.post('/detections', authenticateToken, async (req, res) => {
    try {
        const { imageBase64 } = req.body;
        const userId = req.user.userId;
        
        if (!imageBase64) {
            return res.status(400).json({ error: "Image is required" });
        }
        
        const aiResult = await callAIModel(imageBase64);
        
        const uploadResult = await cloudinary.uploader.upload(imageBase64, {
            folder: "croptech_detections",
            public_id: `user_${userId}_${Date.now()}`,
            resource_type: "image"
        });
        
        const disease = await db.query('SELECT * FROM diseases WHERE name = $1', [aiResult.name]);
        
        if (disease.rows.length === 0) {
            const detection = await db.query(
                `INSERT INTO detections (user_id, image_url, confidence, disease_name_unknown) 
                 VALUES ($1, $2, $3, $4) RETURNING *`,
                [userId, uploadResult.secure_url, aiResult.confidence, aiResult.name]
            );
            
            return res.status(202).json({
                id: detection.rows[0].id,
                diseaseName: aiResult.name,
                confidence: aiResult.confidence,
                status: "unknown",
                message: "Disease detected but not in our database yet. Our agronomist will review.",
                imageUrl: uploadResult.secure_url,
                date: detection.rows[0].created_at
            });
        }
        
        const diseaseInfo = disease.rows[0];
        
        const detection = await db.query(
            `INSERT INTO detections (user_id, disease_id, image_url, confidence) 
             VALUES ($1, $2, $3, $4) RETURNING *`,
            [userId, diseaseInfo.id, uploadResult.secure_url, aiResult.confidence]
        );
        
        const status = aiResult.confidence < 70 ? 'critical' : 
                      aiResult.confidence < 85 ? 'requires_attention' : 'healthy';
        
        res.status(201).json({
            id: detection.rows[0].id,
            crop: diseaseInfo.crop || aiResult.crop,
            diseaseName: diseaseInfo.name,
            confidence: aiResult.confidence,
            symptoms: diseaseInfo.symptoms,
            treatment: diseaseInfo.treatment,
            prevention: diseaseInfo.prevention,
            status: status,
            imageUrl: uploadResult.secure_url,
            date: detection.rows[0].created_at
        });
        
    } catch (error) {
        console.error("Error creating detection:", error);
        res.status(500).json({ error: "Analysis failed. Please try again." });
    }
});

// Get all detections for authenticated user with pagination
router.get('/detections', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { limit = 100, offset = 0 } = req.query;
        
        const detections = await db.query(
            `SELECT d.id, d.image_url, d.confidence, d.created_at, d.crop_type,
                    COALESCE(dis.name, d.disease_name_unknown) as disease_name,
                    CASE WHEN d.confidence < 70 THEN 'critical' WHEN d.confidence < 85 THEN 'requires_attention' ELSE 'healthy' END as status
             FROM detections d
             LEFT JOIN diseases dis ON d.disease_id = dis.id
             WHERE d.user_id = $1
             ORDER BY d.created_at DESC
             LIMIT $2 OFFSET $3`,
            [userId, limit, offset]
        );
        
        const total = await db.query('SELECT COUNT(*) FROM detections WHERE user_id = $1', [userId]);
        
        res.json({
            message: detections.rows.length > 0 ? "Detection history retrieved successfully" : "You haven't made any detections yet",
            count: detections.rows.length,
            total: parseInt(total.rows[0].count),
            detections: detections.rows
        });
        
    } catch (error) {
        console.log(error);
        res.status(500).json({ error: "Unable to fetch your detections" });
    }
});

// Get recent detections for dashboard preview
router.get('/detections/recent', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const limit = req.query.limit || 5;
        
        const recent = await db.query(
            `SELECT d.id, d.image_url, d.confidence, d.created_at, d.crop_type,
                    COALESCE(dis.name, d.disease_name_unknown) as disease_name,
                    CASE WHEN d.confidence < 70 THEN 'critical' WHEN d.confidence < 85 THEN 'requires_attention' ELSE 'healthy' END as status
             FROM detections d
             LEFT JOIN diseases dis ON d.disease_id = dis.id
             WHERE d.user_id = $1
             ORDER BY d.created_at DESC
             LIMIT $2`,
            [userId, limit]
        );
        
        res.json({
            message: "Recent scans retrieved",
            count: recent.rows.length,
            detections: recent.rows
        });
        
    } catch (error) {
        console.log(error);
        res.status(500).json({ error: "Unable to fetch recent scans" });
    }
});

// Get scan activity data for charts
router.get('/detections/activity', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const days = parseInt(req.query.days) || 7;
        
        const activity = await db.query(
            `SELECT TO_CHAR(DATE(created_at), 'Dy') as day, COUNT(*) as count
             FROM detections 
             WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '1 day' * $2
             GROUP BY DATE(created_at)
             ORDER BY MIN(created_at)`,
            [userId, days]
        );
        
        const dayMap = {0: 'Sun', 1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat'};
        const labels = [];
        const data = [];
        
        for (let i = 0; i < days; i++) {
            const date = new Date();
            date.setDate(date.getDate() - (days - 1 - i));
            const dayName = dayMap[date.getDay()];
            labels.push(dayName);
            const found = activity.rows.find(r => r.day === dayName);
            data.push(found ? parseInt(found.count) : 0);
        }
        
        res.json({ labels, data, total: data.reduce((a, b) => a + b, 0) });
        
    } catch (error) {
        console.log("Activity error:", error);
        res.status(500).json({ error: "Unable to fetch activity data" });
    }
});

// Get detailed information for a specific detection by ID
router.get('/detections/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        
        const detection = await db.query(
            `SELECT d.*, dis.name as disease_name, dis.symptoms, dis.treatment, dis.description
             FROM detections d
             LEFT JOIN diseases dis ON d.disease_id = dis.id
             WHERE d.id = $1 AND d.user_id = $2`,
            [id, userId]
        );
        
        if (detection.rows.length === 0) {
            return res.status(404).json({ error: "Detection not found" });
        }
        
        const det = detection.rows[0];
        
        if (!det.disease_id) {
            return res.json({
                id: det.id,
                diseaseName: det.disease_name_unknown || "Unknown",
                confidence: det.confidence,
                imageUrl: det.image_url,
                message: "This disease is not in our database yet. Our agronomist will review.",
                date: det.created_at
            });
        }
        
        res.json({
            id: det.id,
            crop: det.crop_type || "Unknown",
            diseaseName: det.disease_name,
            confidence: det.confidence,
            symptoms: det.symptoms,
            treatment: det.treatment,
            description: det.description,
            imageUrl: det.image_url,
            date: det.created_at
        });
        
    } catch (error) {
        console.log("Error fetching detection:", error);
        res.status(500).json({ error: "Unable to fetch detection details" });
    }
});

// Delete a specific detection by ID
router.delete('/detections/:id', authenticateToken, async (req, res) => {
    try {
        const detectionId = req.params.id;
        const userId = req.user.userId;
        
        const result = await db.query(
            'DELETE FROM detections WHERE id = $1 AND user_id = $2 RETURNING id',
            [detectionId, userId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Detection not found" });
        }
        
        res.json({ message: "Detection deleted successfully" });
        
    } catch (error) {
        console.log("Error deleting detection:", error);
        res.status(500).json({ error: "Unable to delete detection" });
    }
});

// Submit support message to agronomist team
router.post('/contact', authenticateToken, async (req, res) => {
    try {
        const { subject, message, cropType, issueType } = req.body;
        const userId = req.user.userId;
        
        if (!subject || !message) {
            return res.status(400).json({ error: "Subject and message are required" });
        }
        
        await db.query(
            `INSERT INTO support_messages (user_id, subject, message, crop_type, issue_type) 
             VALUES ($1, $2, $3, $4, $5)`,
            [userId, subject, message, cropType || null, issueType || 'general']
        );
        
        res.json({ 
            message: "Your message has been sent to our agronomist team. They will contact you within 24 hours.",
            ticketId: Math.floor(Math.random() * 10000)
        });
        
    } catch (error) {
        console.log("Contact error:", error);
        res.status(500).json({ error: "Unable to send message. Please try again." });
    }
});

// API health check endpoint
router.get('/health', (req, res) => {
    res.json({ 
        status: "CROPTECH API is running", 
        timestamp: new Date(),
        version: "2.0"
    });
});

module.exports = router;