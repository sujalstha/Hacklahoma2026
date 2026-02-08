import React, { useState } from 'react';
import { ArrowLeft, Plus, Camera, Search, ShoppingBag } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import InventoryItem from '../components/Inventory/InventoryItem';

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
    // ... items would ideally come from API/Context
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
    <div className="pb-24 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            onClick={() => navigate(-1)}
          >
            <ArrowLeft size={24} className="text-gray-700" />
          </button>
          <h2 className="text-2xl font-bold text-gray-900">My Inventory</h2>
        </div>
        <div className="bg-primary/10 p-2 rounded-full text-primary">
          <ShoppingBag size={24} />
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100 text-center">
          <h3 className="text-3xl font-bold text-gray-800">{inventoryItems.length}</h3>
          <p className="text-gray-500 text-sm">Total Items</p>
        </div>
        <div className="bg-orange-50 p-4 rounded-2xl shadow-sm border border-orange-100 text-center">
          <h3 className="text-3xl font-bold text-orange-600">{inventoryItems.filter(item => item.status === 'expiring-soon').length}</h3>
          <p className="text-orange-600/80 text-sm">Expiring Soon</p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="relative">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search size={20} className="text-gray-400" />
        </div>
        <input
          type="text"
          className="block w-full pl-10 pr-3 py-3 border border-gray-200 rounded-xl leading-5 bg-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent sm:text-sm shadow-sm transition-shadow"
          placeholder="Search inventory..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {/* Category Filter */}
      <div className="flex gap-2 overflow-x-auto pb-2 no-scrollbar">
        {categories.map((category) => (
          <button
            key={category}
            className={`
              px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap border transition-all
              ${selectedCategory === category
                ? 'bg-gray-900 text-white border-gray-900 shadow-md'
                : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}
            `}
            onClick={() => setSelectedCategory(category)}
          >
            {category}
          </button>
        ))}
      </div>

      {/* Inventory List */}
      <div className="space-y-4">
        {filteredItems.map((item) => (
          <InventoryItem key={item.id} item={item} />
        ))}
      </div>

      {/* Floating Action Buttons */}
      <div className="fixed bottom-24 right-6 flex flex-col gap-3">
        <button className="bg-white text-gray-700 p-3 rounded-full shadow-lg border border-gray-100 hover:bg-gray-50 transition-all">
          <Camera size={24} />
        </button>
        <button className="bg-primary text-white p-4 rounded-full shadow-lg hover:bg-primary-dark transition-all transform hover:scale-105">
          <Plus size={24} />
        </button>
      </div>
    </div>
  );
};

export default InventoryPage;
