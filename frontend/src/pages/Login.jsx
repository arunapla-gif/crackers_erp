import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../store/useAuth';

export default function Login() {
  const [username, setUsername] = useState('');
  const [pin, setPin] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const login = useAuth(state => state.login);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    if (!username || !pin) {
      setError('Please enter both username and PIN');
      return;
    }
    
    setLoading(true);
    setError('');

    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'https://crackers-erp-api.onrender.com/api';
      const res = await fetch(`${apiUrl}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, pin })
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error || 'Login failed');
      }

      // Save user to state & localstorage
      login(data.user, data.token);
      
      // Navigate to dashboard
      navigate('/');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 flex items-center justify-center p-4 relative overflow-hidden" style={{ fontFamily: '"Inter", system-ui, sans-serif' }}>
      {/* Background Orbs */}
      <div className="absolute top-[-10%] left-[-10%] w-[40vw] h-[40vw] bg-indigo-500/20 rounded-full blur-[100px] pointer-events-none"></div>
      <div className="absolute bottom-[-10%] right-[-10%] w-[40vw] h-[40vw] bg-purple-500/20 rounded-full blur-[100px] pointer-events-none"></div>

      <div className="w-full max-w-[420px] relative z-10">
        <div className="bg-white/80 backdrop-blur-2xl p-8 rounded-3xl shadow-[0_20px_60px_rgba(15,23,42,0.08)] border border-white">
          <div className="text-center mb-8">
            <div className="w-16 h-16 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl mx-auto flex items-center justify-center text-white text-2xl font-black shadow-lg shadow-indigo-500/30 mb-4 transform -rotate-3 hover:rotate-0 transition-transform">
              ERP
            </div>
            <h1 className="text-2xl font-black text-slate-800 tracking-tight">Welcome Back</h1>
            <p className="text-sm font-medium text-slate-500 mt-1">Sign in to access Crackers ERP</p>
          </div>

          {error && (
            <div className="mb-6 p-3 bg-rose-50 border border-rose-200 text-rose-600 text-sm font-bold rounded-xl text-center">
              {error}
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-black text-slate-600 uppercase tracking-wider mb-1.5 ml-1">Username</label>
              <input 
                type="text" 
                value={username}
                onChange={e => setUsername(e.target.value)}
                className="w-full h-12 px-4 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium focus:outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 transition-all placeholder:text-slate-400"
                placeholder="Enter username"
                autoComplete="username"
              />
            </div>

            <div>
              <label className="block text-xs font-black text-slate-600 uppercase tracking-wider mb-1.5 ml-1">Secure PIN</label>
              <input 
                type="password" 
                inputMode="numeric"
                pattern="[0-9]*"
                value={pin}
                onChange={e => setPin(e.target.value)}
                className="w-full h-12 px-4 bg-slate-50 border border-slate-200 rounded-xl text-lg tracking-[0.5em] font-black focus:outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 transition-all placeholder:text-slate-400 placeholder:tracking-normal placeholder:font-medium placeholder:text-sm text-center"
                placeholder="Enter PIN"
                autoComplete="current-password"
              />
            </div>

            <button 
              type="submit" 
              disabled={loading}
              className={`w-full h-12 mt-6 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white rounded-xl font-bold shadow-lg shadow-indigo-500/25 transition-all flex items-center justify-center ${loading ? 'opacity-80 scale-[0.98]' : 'hover:-translate-y-0.5 active:scale-[0.98]'}`}
            >
              {loading ? 'Authenticating...' : 'Sign In'}
            </button>
          </form>

          <div className="mt-8 text-center text-xs font-medium text-slate-400">
            Secure Access Portal • Crackers ERP
          </div>
        </div>
      </div>
    </div>
  );
}
