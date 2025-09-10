const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    required: true,
    enum: [
      'order_cancel_request', 
      'order_cancel_approved', 
      'order_cancel_rejected', 
      'order_update',
      'add_to_cart',
      'payment_success',
      'order_status_update'
    ],
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: null,
  },
  isRead: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Number,
    default: () => new Date().getTime(),
  },
});

const Notification = mongoose.model('Notification', notificationSchema);
module.exports = Notification;
