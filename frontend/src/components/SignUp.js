import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import apiService, { ApiError } from '../services/apiService';

const SignUp = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    birthdate: '',
    phoneNumber: '',
    address: {
      street: '',
      city: '',
      zip: '',
      state: ''
    }
  });
  const [errors, setErrors] = useState({});
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleChange = (e) => {
    const { name, value } = e.target;
    
    // Handle nested address fields
    if (name.startsWith('address.')) {
      const addressField = name.split('.')[1];
      setFormData(prev => ({
        ...prev,
        address: {
          ...prev.address,
          [addressField]: value
        }
      }));
    } else {
      setFormData(prev => ({
        ...prev,
        [name]: value
      }));
    }
    
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  const validateForm = () => {
    const newErrors = {};
    
    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    }
    
    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email is invalid';
    }
    
    if (!formData.password) {
      newErrors.password = 'Password is required';
    }
    
    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Please confirm your password';
    }
    
    if (!formData.birthdate) {
      newErrors.birthdate = 'Birthdate is required';
    }
    
    if (!formData.phoneNumber.trim()) {
      newErrors.phoneNumber = 'Phone number is required';
    }
    
    if (!formData.address.street.trim()) {
      newErrors['address.street'] = 'Street address is required';
    }
    
    if (!formData.address.city.trim()) {
      newErrors['address.city'] = 'City is required';
    }
    
    if (!formData.address.state.trim()) {
      newErrors['address.state'] = 'State is required';
    }
    
    if (!formData.address.zip.trim()) {
      newErrors['address.zip'] = 'ZIP code is required';
    }
    
    return newErrors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const newErrors = validateForm();

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setIsLoading(true);
    setErrors({}); // Clear any previous errors

    try {
      const userData = await apiService.signup(formData);

      navigate('/login?signup=success');
      
    } catch (error) {
      console.error('Signup error:', error);

      if (error instanceof ApiError) {
        if (error.isValidationError()) {
          // Handle validation errors from backend
          setErrors(error.getFormattedValidationErrors());
        } else if (error.isNetworkError()) {
          setErrors({ 
            general: error.message 
          });
        } else {
          setErrors({ 
            general: 'Registration failed. Please try again.' 
          });
        }
      } else {
        setErrors({ 
          general: 'Registration failed. Please try again.' 
        });
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card-wide">
        <div>
          {/* ICON PERSON */}
          <div className="auth-icon">
            <svg className="h-8 w-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
            </svg>
          </div>

          <h2 className="auth-title">
            Create your account
          </h2>
          <p className="auth-subtitle">
            Or{' '}
            <Link
              to="/login"
              className="auth-link"
            >
              sign in to your existing account
            </Link>
          </p>
        </div>
        
        <form className="auth-form" onSubmit={handleSubmit}>
          {errors.general && (
            <div className="alert-error">
              {errors.general}
            </div>
          )}
          
          <div className="space-y-6">
            {/* Personal Information */}
            <div className="form-section">
              <h3 className="form-section-title">Personal Information</h3>
              <div className="space-y-4">
                <div>
                  <label htmlFor="name" className="form-label">
                    Full Name
                  </label>
                  <input
                    id="name"
                    name="name"
                    type="text"
                    autoComplete="name"
                    value={formData.name}
                    onChange={handleChange}
                    className={errors.name ? 'input-invalid' : 'input-valid'}
                    placeholder="John Doe"
                  />
                  {errors.name && (
                    <p className="form-error">{errors.name}</p>
                  )}
                </div>
                
                <div className="form-grid-2">
                  <div>
                    <label htmlFor="email" className="form-label">
                      Email address
                    </label>
                    <input
                      id="email"
                      name="email"
                      type="email"
                      autoComplete="email"
                      value={formData.email}
                      onChange={handleChange}
                      className={errors.email ? 'input-invalid' : 'input-valid'}
                      placeholder="john.doe@example.com"
                    />
                    {errors.email && (
                      <p className="form-error">{errors.email}</p>
                    )}
                  </div>
                  
                  <div>
                    <label htmlFor="phoneNumber" className="form-label">
                      Phone Number
                    </label>
                    <input
                      id="phoneNumber"
                      name="phoneNumber"
                      type="tel"
                      autoComplete="tel"
                      value={formData.phoneNumber}
                      onChange={handleChange}
                      className={errors.phoneNumber ? 'input-invalid' : 'input-valid'}
                      placeholder="(555) 123-4567"
                    />
                    {errors.phoneNumber && (
                      <p className="form-error">{errors.phoneNumber}</p>
                    )}
                  </div>
                </div>
                
                <div>
                  <label htmlFor="birthdate" className="form-label">
                    Date of Birth
                  </label>
                  <input
                    id="birthdate"
                    name="birthdate"
                    type="date"
                    autoComplete="bday"
                    value={formData.birthdate}
                    onChange={handleChange}
                    className={errors.birthdate ? 'input-invalid' : 'input-valid'}
                  />
                  {errors.birthdate && (
                    <p className="form-error">{errors.birthdate}</p>
                  )}
                </div>
              </div>
            </div>

            {/* Address Information */}
            <div className="form-section">
              <h3 className="form-section-title">Address Information</h3>
              <div className="space-y-4">
                <div>
                  <label htmlFor="address.street" className="form-label">
                    Street Address
                  </label>
                  <input
                    id="address.street"
                    name="address.street"
                    type="text"
                    autoComplete="street-address"
                    value={formData.address.street}
                    onChange={handleChange}
                    className={errors['address.street'] ? 'input-invalid' : 'input-valid'}
                    placeholder="123 Main Street"
                  />
                  {errors['address.street'] && (
                    <p className="form-error">{errors['address.street']}</p>
                  )}
                </div>
                
                <div className="form-grid-2">
                  <div>
                    <label htmlFor="address.city" className="form-label">
                      City
                    </label>
                    <input
                      id="address.city"
                      name="address.city"
                      type="text"
                      autoComplete="address-level2"
                      value={formData.address.city}
                      onChange={handleChange}
                      className={errors['address.city'] ? 'input-invalid' : 'input-valid'}
                      placeholder="New York"
                    />
                    {errors['address.city'] && (
                      <p className="form-error">{errors['address.city']}</p>
                    )}
                  </div>
                  
                  <div>
                    <label htmlFor="address.state" className="form-label">
                      State
                    </label>
                    <input
                      id="address.state"
                      name="address.state"
                      type="text"
                      autoComplete="address-level1"
                      value={formData.address.state}
                      onChange={handleChange}
                      className={errors['address.state'] ? 'input-invalid' : 'input-valid'}
                      placeholder="NY"
                    />
                    {errors['address.state'] && (
                      <p className="form-error">{errors['address.state']}</p>
                    )}
                  </div>
                </div>
                
                <div className="w-1/2">
                  <label htmlFor="address.zip" className="form-label">
                    ZIP Code
                  </label>
                  <input
                    id="address.zip"
                    name="address.zip"
                    type="text"
                    autoComplete="postal-code"
                    value={formData.address.zip}
                    onChange={handleChange}
                    className={errors['address.zip'] ? 'input-invalid' : 'input-valid'}
                    placeholder="10001"
                  />
                  {errors['address.zip'] && (
                    <p className="form-error">{errors['address.zip']}</p>
                  )}
                </div>
              </div>
            </div>

            {/* Security Information */}
            <div className="form-section">
              <h3 className="form-section-title">Security Information</h3>
              <div className="space-y-4">
                <div>
                  <label htmlFor="password" className="form-label">
                    Password
                  </label>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    autoComplete="new-password"
                    value={formData.password}
                    onChange={handleChange}
                    className={errors.password ? 'input-invalid' : 'input-valid'}
                    placeholder="Enter your password"
                  />
                  {errors.password && (
                    <p className="form-error">{errors.password}</p>
                  )}
                </div>
                
                <div>
                  <label htmlFor="confirmPassword" className="form-label">
                    Confirm Password
                  </label>
                  <input
                    id="confirmPassword"
                    name="confirmPassword"
                    type="password"
                    autoComplete="new-password"
                    value={formData.confirmPassword}
                    onChange={handleChange}
                    className={errors.confirmPassword ? 'input-invalid' : 'input-valid'}
                    placeholder="Confirm your password"
                  />
                  {errors.confirmPassword && (
                    <p className="form-error">{errors.confirmPassword}</p>
                  )}
                </div>
              </div>
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={isLoading}
              className={`group ${isLoading ? 'btn-submit-loading' : 'btn-submit-normal'}`}
            >
              {isLoading ? (
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              ) : null}
              {isLoading ? 'Creating account...' : 'Create account'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default SignUp;
