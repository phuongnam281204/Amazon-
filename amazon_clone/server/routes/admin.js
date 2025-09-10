const express = require("express");
const adminRouter = express.Router();
const admin = require("../middlewares/admin");
const { Product } = require("../models/product");
const Order  = require("../models/order");
const Notification = require("../models/notification");
const CancelRequest = require("../models/cancelRequest");

// Add Product
adminRouter.post("/admin/add-product", admin, async (req, res) => {
  try {
    const { name, description, images, quantity, price, category } = req.body;
    let product = new Product({
      name,
      description,
      images,
      quantity,
      price,
      category,
    });
    product = await product.save();
    res.json(product);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get all your products
adminRouter.get("/admin/get-products", admin, async (req, res) => {
  try {
    const products = await Product.find({});
    res.json(products);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Delete the product
adminRouter.post("/admin/delete-product", admin, async (req, res) => {
  try {
    const { id } = req.body;
    let product = await Product.findByIdAndDelete(id);
    res.json(product);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get single product by ID (for editing)
adminRouter.get("/admin/get-product/:id", admin, async (req, res) => {
  try {
    const { id } = req.params;
    const product = await Product.findById(id);

    if (!product) {
      return res.status(404).json({ msg: "Product not found" });
    }

    res.json(product);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Update/Edit product
adminRouter.put("/admin/edit-product", admin, async (req, res) => {
  try {
    const { id, name, description, images, quantity, price, category } = req.body;

    // Check if product exists
    let product = await Product.findById(id);
    if (!product) {
      return res.status(404).json({ msg: "Product not found" });
    }

    // Update product
    product = await Product.findByIdAndUpdate(
      id,
      {
        name,
        description,
        images,
        quantity,
        price,
        category,
      },
      { new: true } // Return updated document
    );

    res.json(product);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get all orders
adminRouter.get("/admin/get-orders", admin, async (req, res) => {
  try {
    const orders = await Order.find({});
    res.json(orders);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Update order status
adminRouter.post("/admin/change-order-status", admin, async (req, res) => {
  try {
    const { id, status } = req.body;
    let order = await Order.findById(id);
    
    if (!order) {
      return res.status(404).json({ msg: "Order not found" });
    }
    
    const oldStatus = order.status;
    order.status = status;
    order = await order.save();
    
    // Create notification for user about status change
    const statusText = {
      0: 'Pending',
      1: 'Confirmed', 
      2: 'Shipped',
      3: 'Delivered',
      4: 'Cancelled'
    };
    
    let title = 'Order Status Updated';
    let message = `Your order #${id.slice(-8)} has been updated to ${statusText[status]}.`;
    
    // Customize message based on status
    switch (status) {
      case 1:
        message = `Your order #${id.slice(-8)} has been confirmed and is being processed.`;
        break;
      case 2:
        message = `Great news! Your order #${id.slice(-8)} has been shipped.`;
        break;
      case 3:
        title = 'Order Delivered';
        message = `Your order #${id.slice(-8)} has been delivered successfully.`;
        break;
      case 4:
        title = 'Order Cancelled';
        message = `Your order #${id.slice(-8)} has been cancelled.`;
        break;
    }
    
    // Create notification
    await Notification.create({
      userId: order.userId,
      title: title,
      message: message,
      type: 'order_status_update',
      data: {
        orderId: id,
        oldStatus: statusText[oldStatus] || 'Unknown',
        newStatus: statusText[status] || 'Unknown'
      },
      createdAt: new Date().getTime()
    });
    
    res.json(order);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
adminRouter.post("/admin/change-order-statusUser", async (req, res) => {
  try {
    const { id, status } = req.body;
    let order = await Order.findById(id);
    order.status = status;
    order = await order.save();
    res.json(order);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
// analytics
adminRouter.get("/admin/analytics", admin, async (req, res) => {
  try {
    const orders = await Order.find({});
    let totalEarnings = 0;

    for (let i = 0; i < orders.length; i++) {
      for (let j = 0; j < orders[i].products.length; j++) {
        totalEarnings +=
          orders[i].products[j].quantity * orders[i].products[j].product.price;
      }
    }
     // CATEGORY WISE ORDER FETCHING
    let mobileEarnings = await fetchCategoryWiseProduct("Mobiles");
    let essentialEarnings = await fetchCategoryWiseProduct("Essentials");
    let applianceEarnings = await fetchCategoryWiseProduct("Appliances");
    let booksEarnings = await fetchCategoryWiseProduct("Books");
    let fashionEarnings = await fetchCategoryWiseProduct("Fashion");

    let earnings = {
      totalEarnings,
      mobileEarnings,
      essentialEarnings,
      applianceEarnings,
      booksEarnings,
      fashionEarnings,
    };
    
   res.json(earnings);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

async function fetchCategoryWiseProduct(category) {
  let earnings = 0;
  let categoryOrders = await Order.find({
    "products.product.category": category,
  });

  for (let i = 0; i < categoryOrders.length; i++) {
    for (let j = 0; j < categoryOrders[i].products.length; j++) {
      earnings +=
        categoryOrders[i].products[j].quantity *
        categoryOrders[i].products[j].product.price;
    }
  }
  return earnings;
}

// Get all cancel requests
adminRouter.get("/admin/cancel-requests", admin, async (req, res) => {
  try {
    const cancelRequests = await CancelRequest.find({})
      .sort({ createdAt: -1 });
    res.json(cancelRequests);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Handle cancel request (approve/reject)
adminRouter.post("/admin/handle-cancel-request", admin, async (req, res) => {
  try {
    const { orderId, approve } = req.body;
    
    // Find the cancel request
    const cancelRequest = await CancelRequest.findOne({ 
      orderId, 
      status: 'pending' 
    });
    
    if (!cancelRequest) {
      return res.status(404).json({ msg: "Cancel request not found" });
    }
    
    // Update cancel request status
    cancelRequest.status = approve ? 'approved' : 'rejected';
    cancelRequest.reviewedAt = new Date().getTime();
    cancelRequest.reviewedBy = req.user;
    await cancelRequest.save();
    
    if (approve) {
      // Update order status to cancelled (status 4)
      await Order.findByIdAndUpdate(orderId, { status: 4 });
      
      // Create notification for user
      await Notification.create({
        userId: cancelRequest.userId,
        title: 'Order Cancellation Approved',
        message: `Your order #${orderId.slice(-8)} has been cancelled`,
        type: 'order_cancel_approved',
        data: { orderId },
      });
    } else {
      // Create notification for user about rejection
      await Notification.create({
        userId: cancelRequest.userId,
        title: 'Order Cancellation Rejected',
        message: `Your cancellation request for order #${orderId.slice(-8)} has been rejected`,
        type: 'order_cancel_rejected',
        data: { orderId },
      });
    }
    
    res.json({ 
      message: approve ? "Order cancelled successfully" : "Cancel request rejected",
      cancelRequest 
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = adminRouter;