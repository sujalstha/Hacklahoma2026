import React, { useState } from 'react';
import { ArrowLeft, Plus, Camera, Search } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import InventoryItem from '../components/Inventory/InventoryItem';
import './InventoryPage.css';

const InventoryPage = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');

  // Mock inventory data
  const inventoryItems = [
    {
      id: 1,
      name: 'Chicken Breast',
      category: 'Proteins',
      quantity: '500g',
      expiryDate: '2026-02-15',
      status: 'fresh',
      image: 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=200'
    },
    {
      id: 2,
      name: 'Tomatoes',
      category: 'Produce',
      quantity: '6 pieces',
      expiryDate: '2026-02-10',
      status: 'expiring-soon',
      image: 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=200'
    },
    {
      id: 3,
      name: 'Milk',
      category: 'Dairy',
      quantity: '1L',
      expiryDate: '2026-02-12',
      status: 'fresh',
      image: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=200'
    },
    {
      id: 4,
      name: 'Brown Rice',
      category: 'Grains',
      quantity: '2kg',
      expiryDate: '2027-01-01',
      status: 'fresh',
      image: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=200'
    },
    {
      id: 5,
      name: 'Spinach',
      category: 'Produce',
      quantity: '200g',
      expiryDate: '2026-02-08',
      status: 'expiring-soon',
      image: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=200'
    },
    {
      id: 6,
      name: 'Eggs',
      category: 'Proteins',
      quantity: '12 pieces',
      expiryDate: '2026-02-20',
      status: 'fresh',
      image: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=200'
    }
  ];

  const categories = ['All', 'Produce', 'Dairy', 'Proteins', 'Grains'];

  const filteredItems = inventoryItems.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'All' || item.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  return (
    <div className="inventory-page">
      {/* Header */}
      <div className="inventory-header">
        <button className="back-button" onClick={() => navigate(-1)}>
          <ArrowLeft size={24} />
        </button>
        <h2>My Inventory</h2>
      </div>

      {/* Stats */}
      <div className="inventory-stats">
        <div className="stat-card">
          <h3>{inventoryItems.length}</h3>
          <p>Total Items</p>
        </div>
        <div className="stat-card expiring">
          <h3>{inventoryItems.filter(item => item.status === 'expiring-soon').length}</h3>
          <p>Expiring Soon</p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="inventory-search">
        <Search size={20} color="#6c757d" />
        <input
          type="text"
          placeholder="Search inventory..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {/* Category Filter */}
      <div className="category-filter">
        {categories.map((category) => (
          <button
            key={category}
            className={`filter-chip ${selectedCategory === category ? 'active' : ''}`}
            onClick={() => setSelectedCategory(category)}
          >
            {category}
          </button>
        ))}
      </div>

      {/* Inventory List */}
      <div className="inventory-list">
        {filteredItems.map((item) => (
          <InventoryItem key={item.id} item={item} />
        ))}
      </div>

      {/* Floating Action Buttons */}
      <div className="floating-actions">
        <button className="fab secondary">
          <Camera size={24} />
        </button>
        <button className="fab primary">
          <Plus size={24} />
        </button>
      </div>
    </div>
  );
};

export default InventoryPage;
