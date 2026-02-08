import React from 'react';
import { Calendar, Package } from 'lucide-react';
import './InventoryItem.css';

const InventoryItem = ({ item }) => {
  const getStatusColor = (status) => {
    switch (status) {
      case 'fresh':
        return '#2d5a3d';
      case 'expiring-soon':
        return '#ff6b35';
      case 'expired':
        return '#dc3545';
      default:
        return '#6c757d';
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    const options = { month: 'short', day: 'numeric' };
    return date.toLocaleDateString('en-US', options);
  };

  return (
    <div className="inventory-item">
      <div className="item-image">
        <img src={item.image} alt={item.name} />
        <div 
          className="status-indicator" 
          style={{ backgroundColor: getStatusColor(item.status) }}
        />
      </div>
      
      <div className="item-details">
        <h4 className="item-name">{item.name}</h4>
        <div className="item-meta">
          <span className="item-category">{item.category}</span>
          <span className="item-quantity">
            <Package size={14} />
            {item.quantity}
          </span>
        </div>
        <div className="item-expiry">
          <Calendar size={14} />
          <span>Expires: {formatDate(item.expiryDate)}</span>
        </div>
      </div>

      <button className="item-menu">⋮</button>
    </div>
  );
};

export default InventoryItem;
