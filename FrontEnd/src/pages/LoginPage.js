import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock, Eye, EyeOff, ChefHat } from 'lucide-react';
import './LoginPage.css';

const LoginPage = () => {
  const navigate = useNavigate();
  const [isLogin, setIsLogin] = useState(true);
  const [showPassword, setShowPassword] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: ''
  });

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    // TODO: Add authentication logic here
    console.log('Form submitted:', formData);
    
    // For now, just navigate to home
    // Later, add API call for authentication
    navigate('/home');
  };

  const toggleMode = () => {
    setIsLogin(!isLogin);
    setFormData({ name: '', email: '', password: '' });
  };

  return (
    <div className="login-page">
      {/* Background Design */}
      <div className="login-background">
        <div className="background-circle circle-1"></div>
        <div className="background-circle circle-2"></div>
        <div className="background-circle circle-3"></div>
      </div>

      {/* Login Container */}
      <div className="login-container">
        {/* Logo & Title */}
        <div className="login-header">
          <div className="app-logo">
            <ChefHat size={48} color="#2d5a3d" />
          </div>
          <h1 className="app-title">What's For Dinner</h1>
          <p className="app-tagline">
            {isLogin 
              ? 'Welcome back! Ready to cook?' 
              : 'Start your culinary journey'}
          </p>
        </div>

        {/* Form */}
        <form className="login-form" onSubmit={handleSubmit}>
          {/* Name Field (Sign Up Only) */}
          {!isLogin && (
            <div className="form-group">
              <label htmlFor="name">Full Name</label>
              <div className="input-wrapper">
                <input
                  type="text"
                  id="name"
                  name="name"
                  placeholder="Enter your name"
                  value={formData.name}
                  onChange={handleInputChange}
                  required={!isLogin}
                />
              </div>
            </div>
          )}

          {/* Email Field */}
          <div className="form-group">
            <label htmlFor="email">Email Address</label>
            <div className="input-wrapper">
              <Mail size={20} className="input-icon" />
              <input
                type="email"
                id="email"
                name="email"
                placeholder="Enter your email"
                value={formData.email}
                onChange={handleInputChange}
                required
              />
            </div>
          </div>

          {/* Password Field */}
          <div className="form-group">
            <label htmlFor="password">Password</label>
            <div className="input-wrapper">
              <Lock size={20} className="input-icon" />
              <input
                type={showPassword ? 'text' : 'password'}
                id="password"
                name="password"
                placeholder="Enter your password"
                value={formData.password}
                onChange={handleInputChange}
                required
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
          </div>

          {/* Forgot Password (Login Only) */}
          {isLogin && (
            <div className="form-footer">
              <button type="button" className="forgot-password">
                Forgot Password?
              </button>
            </div>
          )}

          {/* Submit Button */}
          <button type="submit" className="submit-button">
            {isLogin ? 'Sign In' : 'Create Account'}
          </button>

          {/* Social Login Divider */}
          <div className="divider">
            <span>or continue with</span>
          </div>

          {/* Social Login Buttons */}
          <div className="social-buttons">
            <button type="button" className="social-button google">
              <svg width="20" height="20" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Google
            </button>
            <button type="button" className="social-button apple">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
              </svg>
              Apple
            </button>
          </div>
        </form>

        {/* Toggle Login/Signup */}
        <div className="toggle-mode">
          <p>
            {isLogin ? "Don't have an account? " : "Already have an account? "}
            <button type="button" onClick={toggleMode} className="toggle-button">
              {isLogin ? 'Sign Up' : 'Sign In'}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
