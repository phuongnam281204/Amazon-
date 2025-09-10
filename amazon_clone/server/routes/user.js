const express = require('express');
const userRouter = express.Router();
const auth = require('../middlewares/auth');
const Order = require("../models/order");
const { Product } = require("../models/product");
const User = require("../models/user");
const Notification = require("../models/notification");
const CancelRequest = require("../models/cancelRequest");

userRouter.post("/api/add-to-cart", auth, async (req, res) => {
  try {
    const { id } = req.body;
    const product = await Product.findById(id);
    let user = await User.findById(req.user);

    if (user.cart.length == 0) {
      user.cart.push({ product, quantity: 1 });
    } else {
      let isProductFound = false;
      for (let i = 0; i < user.cart.length; i++) {
        if (user.cart[i].product._id.equals(product._id)) {
          isProductFound = true;
        }
      }

      if (isProductFound) {
        let producttt = user.cart.find((productt) =>
          productt.product._id.equals(product._id)
        );
        producttt.quantity += 1;
      } else {
        user.cart.push({ product, quantity: 1 });
      }
    }
    user = await user.save();
    
    // Create add to cart notification
    try {
      await Notification.create({
        userId: req.user,
        title: 'Product Added to Cart',
        message: `You have successfully added "${product.name}" to your cart.`,
        type: 'add_to_cart',
        data: { productName: product.name, productId: product._id },
        createdAt: new Date().getTime()
      });
    } catch (notificationError) {
      // Silent fail for notification - don't block cart operation
      console.log('Failed to create add to cart notification:', notificationError);
    }
    
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

userRouter.delete("/api/remove-from-cart/:id", auth, async (req, res) => {
  try {
    const { id } = req.params;
    const product = await Product.findById(id);
    let user = await User.findById(req.user);

    for (let i = 0; i < user.cart.length; i++) {
      if (user.cart[i].product._id.equals(product._id)) {
        if (user.cart[i].quantity == 1) {
          user.cart.splice(i, 1);
        } else {
          user.cart[i].quantity -= 1;
        }
      }
    }
    user = await user.save();
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// update user profile
userRouter.post("/api/update-profile", auth, async (req, res) => {
  try {
    const { name, phone, address, avatar } = req.body;
    let user = await User.findById(req.user);
    
    if (name) user.name = name;
    if (phone !== undefined) user.phone = phone;
    if (address) user.address = address;
    if (avatar) user.avatar = avatar;
    
    user = await user.save();
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// save user phone
userRouter.post("/api/save-user-phone", auth, async (req, res) => {
  try {
    const { phone } = req.body;
    let user = await User.findById(req.user);
    user.phone = phone;
    user = await user.save();
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// save user address
userRouter.post("/api/save-user-address", auth, async (req, res) => {
  try {
    const { address } = req.body;
    let user = await User.findById(req.user);
    user.address = address;
    user = await user.save();
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// order product
userRouter.post("/api/order", auth, async (req, res) => {
  try {
    const { cart, totalPrice, address, paymentMethod = 'Online' } = req.body;
    let products = [];

    for (let i = 0; i < cart.length; i++) {
      let product = await Product.findById(cart[i].product._id);
      if (product.quantity >= cart[i].quantity) {
        product.quantity -= cart[i].quantity;
        products.push({ product, quantity: cart[i].quantity });
        await product.save();
      } else {
        return res
          .status(400)
          .json({ msg: `${product.name} is out of stock!` });
      }
    }

    let user = await User.findById(req.user);
    user.cart = [];
    user = await user.save();

    let order = new Order({
      products,
      totalPrice,
      address,
      userId: req.user,
      orderedAt: new Date().getTime(),
      paymentMethod: paymentMethod, // Add payment method
    });
    order = await order.save();
    
    // Create payment success notification
    try {
      await Notification.create({
        userId: req.user,
        title: 'Payment Successful',
        message: `Your payment of $${totalPrice.toFixed(2)} has been processed successfully.`,
        type: 'payment_success',
        data: { 
          orderId: order._id, 
          amount: totalPrice,
          paymentMethod: paymentMethod
        },
        createdAt: new Date().getTime()
      });
    } catch (notificationError) {
      // Silent fail for notification - don't block order operation
      console.log('Failed to create payment success notification:', notificationError);
    }
    
    res.json(order);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

userRouter.get("/api/orders/me", auth, async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.user });
    res.json(orders);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Add to wishlist
userRouter.post("/api/add-to-wishlist", auth, async (req, res) => {
  try {
    const { productId } = req.body;
    let user = await User.findById(req.user);
    
    // Check if product is already in wishlist
    if (!user.wishlist.includes(productId)) {
      user.wishlist.push(productId);
      user = await user.save();
    }
    
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Remove from wishlist
userRouter.delete("/api/remove-from-wishlist", auth, async (req, res) => {
  try {
    const { productId } = req.body;
    let user = await User.findById(req.user);
    
    user.wishlist = user.wishlist.filter(id => !id.equals(productId));
    user = await user.save();
    
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get wishlist
userRouter.get("/api/wishlist", auth, async (req, res) => {
  try {
    const user = await User.findById(req.user).populate('wishlist');
    res.json(user.wishlist);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get user notifications
userRouter.get("/api/notifications", auth, async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.user })
      .sort({ createdAt: -1 });
    res.json(notifications);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get unread notifications count
userRouter.get("/api/notifications/unread-count", auth, async (req, res) => {
  try {
    const count = await Notification.countDocuments({ 
      userId: req.user, 
      isRead: false 
    });
    res.json({ count });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Mark notification as read
userRouter.patch("/api/notifications/:id/read", auth, async (req, res) => {
  try {
    const notification = await Notification.findByIdAndUpdate(
      req.params.id,
      { isRead: true },
      { new: true }
    );
    res.json(notification);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Mark all notifications as read
userRouter.patch("/api/notifications/mark-all-read", auth, async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user },
      { isRead: true }
    );
    res.json({ message: "All notifications marked as read" });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Create notification
userRouter.post("/api/notifications/create", auth, async (req, res) => {
  try {
    const { type, title, message, data } = req.body;
    
    const notification = new Notification({
      userId: req.user,
      type,
      title,
      message,
      data,
      createdAt: new Date().getTime()
    });
    
    await notification.save();
    res.json({ message: "Notification created successfully" });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Request order cancellation
userRouter.post("/api/orders/request-cancel", auth, async (req, res) => {
  try {
    const { orderId, reason } = req.body;
    
    // Check if order exists and belongs to user
    const order = await Order.findOne({ _id: orderId, userId: req.user });
    if (!order) {
      return res.status(404).json({ msg: "Order not found" });
    }
    
    // Check if order can be cancelled (not already delivered or cancelled)
    if (order.status >= 3) {
      return res.status(400).json({ msg: "Order cannot be cancelled" });
    }
    
    // Check if there's already a pending cancel request
    const existingRequest = await CancelRequest.findOne({ 
      orderId, 
      status: 'pending' 
    });
    if (existingRequest) {
      return res.status(400).json({ msg: "Cancel request already pending" });
    }
    
    // Create cancel request
    const cancelRequest = new CancelRequest({
      orderId,
      userId: req.user,
      reason,
    });
    
    await cancelRequest.save();
    
    // Create notification for admins
    const adminUsers = await User.find({ type: 'admin' });
    const notifications = adminUsers.map(admin => ({
      userId: admin._id,
      title: 'New Order Cancellation Request',
      message: `Order #${orderId.slice(-8)} cancellation requested`,
      type: 'order_cancel_request',
      data: { orderId, reason },
    }));
    
    await Notification.insertMany(notifications);
    
    res.json({ message: "Cancellation request submitted successfully" });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = userRouter;
