import { Router } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { db } from '../services/db';

const router = Router();

router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Username and password are required' });
  }

  try {
    const [rows] = await db.query('SELECT * FROM `user` WHERE username = ? LIMIT 1', [username]);
    const user = (rows as any[])[0];

    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) {
        throw new Error('JWT_SECRET is not defined in the environment variables.');
    }

    const token = jwt.sign(
      { sub: user.id, role: user.role, employee_id: user.employee_id },
      secret,
      { expiresIn: process.env.JWT_EXPIRES_IN || '3600s' }
    );

    // Update last_login
    await db.query('UPDATE `user` SET last_login = NOW() WHERE id = ?', [user.id]);

    res.json({
      accessToken: token,
      role: user.role,
      employee_id: user.employee_id,
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

export default router;
