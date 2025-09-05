'use client';
import { useState } from 'react';

export default function LoginPage() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const formData = new FormData(e.currentTarget);
    const body = {
      username: formData.get('username'),
      password: formData.get('password')
    };

    try {
      // The backend API is running on a different port, so we need the full URL.
      // In a real application, this should be an environment variable.
      const res = await fetch('http://localhost:3001/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      });

      if (!res.ok) {
        const errorData = await res.json();
        throw new Error(errorData.message || 'Identifiants invalides');
      }

      const data = await res.json();

      // TODO: Store the accessToken securely (e.g., in an httpOnly cookie or localStorage)
      // For this example, we'll just redirect.
      if (data.accessToken) {
        localStorage.setItem('accessToken', data.accessToken);
        window.location.href = '/dashboard';
      }

    } catch (err: any) {
      setError(err.message || 'Erreur de connexion');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="relative min-h-screen w-full">
      {/* Background = logo */}
      <div
        className="absolute inset-0 bg-center bg-no-repeat bg-cover"
        style={{ backgroundImage: `url(${process.env.NEXT_PUBLIC_COMPANY_LOGO_URL || '/logo.png'})` }}
      />
      {/* Overlay sombre */}
      <div className="absolute inset-0 bg-black/50" />

      {/* Modal */}
      <div className="relative z-10 min-h-screen flex items-center justify-center p-4">
        <form onSubmit={onSubmit} className="w-full max-w-md bg-white/90 backdrop-blur rounded-2xl shadow-xl p-8">
          <h1 className="text-2xl font-semibold text-center mb-6">Connexion</h1>
          {error && (
            <div className="mb-4 text-sm text-red-600 bg-red-50 border border-red-200 rounded p-3" role="alert">
              {error}
            </div>
          )}
          <div className="mb-4">
            <label htmlFor="username" className="block text-sm font-medium mb-1">Utilisateur</label>
            <input
              id="username"
              name="username"
              type="text"
              className="w-full rounded-xl border px-4 py-2 focus:outline-none focus:ring focus:ring-black/10"
              placeholder="ex: jdoe"
              required
            />
          </div>

          <div className="mb-6">
            <label htmlFor="password" className="block text-sm font-medium mb-1">Mot de passe</label>
            <input
              id="password"
              name="password"
              type="password"
              className="w-full rounded-xl border px-4 py-2 focus:outline-none focus:ring focus:ring-black/10"
              placeholder="••••••••"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-2xl bg-black text-white py-2.5 font-medium hover:opacity-90 transition disabled:opacity-60"
          >
            {loading ? 'Connexion...' : 'Se connecter'}
          </button>
        </form>
      </div>
    </div>
  );
}
