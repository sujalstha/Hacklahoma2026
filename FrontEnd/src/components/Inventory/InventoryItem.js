import React from 'react';
import { Calendar, Package, MoreVertical } from 'lucide-react';

const InventoryItem = ({ item }) => {
  const getStatusColor = (status) => {
    switch (status) {
      case 'fresh':
        return 'bg-green-100 text-green-700';
      case 'expiring-soon':
        return 'bg-orange-100 text-orange-700';
      case 'expired':
        return 'bg-red-100 text-red-700';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    const options = { month: 'short', day: 'numeric' };
    return date.toLocaleDateString('en-US', options);
  };

  return (
    <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex items-center justify-between hover:shadow-md transition-shadow">
      <div className="flex items-center gap-4">
        <div className="relative w-16 h-16 rounded-xl overflow-hidden bg-gray-100">
          <img
            src={item.image}
            alt={item.name}
            className="w-full h-full object-cover"
          />
        </div>

        <div>
          <h4 className="font-bold text-gray-800 text-lg mb-1">{item.name}</h4>
          <div className="flex flex-wrap gap-2 text-sm text-gray-500">
            <span className="flex items-center gap-1 bg-gray-50 px-2 py-0.5 rounded-md">
              <Package size={12} />
              {item.quantity}
            </span>
            <span className={`px-2 py-0.5 rounded-md text-xs font-medium ${getStatusColor(item.status)}`}>
              {item.status.replace('-', ' ')}
            </span>
          </div>
        </div>
      </div>

      <div className="flex flex-col items-end gap-2">
        <button className="text-gray-400 hover:text-gray-600 p-1">
          <MoreVertical size={20} />
        </button>
        <div className="flex items-center gap-1 text-xs text-orange-600 bg-orange-50 px-2 py-1 rounded-lg">
          <Calendar size={12} />
          <span>{formatDate(item.expiryDate)}</span>
        </div>
      </div>
    </div>
  );
};

export default InventoryItem;
