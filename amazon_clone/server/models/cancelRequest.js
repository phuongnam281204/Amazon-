const mongoose = require('mongoose');

const cancelRequestSchema = new mongoose.Schema({
  orderId: {
    type: String,
    required: true,
  },
  userId: {
    type: String,
    required: true,
  },
  reason: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  adminResponse: {
    type: String,
    default: '',
  },
  createdAt: {
    type: Number,
    default: () => new Date().getTime(),
  },
  reviewedAt: {
    type: Number,
    default: null,
  },
  reviewedBy: {
    type: String,
    default: null,
  },
});

const CancelRequest = mongoose.model('CancelRequest', cancelRequestSchema);
module.exports = CancelRequest;
