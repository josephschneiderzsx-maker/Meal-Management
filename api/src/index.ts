import express, { Express, Request, Response } from 'express';
import dotenv from 'dotenv';
import authRouter from './routes/auth';

dotenv.config();

const app: Express = express();
const port = process.env.PORT || 3001;

// Middleware to parse JSON bodies
app.use(express.json());

// Mount the authentication router
app.use('/api/auth', authRouter);

app.get('/', (req: Request, res: Response) => {
  res.send('Express + TypeScript Server');
});

app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});
