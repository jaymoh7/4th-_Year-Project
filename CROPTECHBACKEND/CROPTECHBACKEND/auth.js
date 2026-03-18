const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
    // Get token from Authorization header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    // If no token, deny access
    if (!token) {
        return res.status(401).json({ error: "Access denied. No token provided." });
    }
    
    // Verify token
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: "Invalid or expired token" });
        }
        
        // Attach user to request for other routes to use
        req.user = user;
        next();
    });
}

module.exports = authenticateToken;