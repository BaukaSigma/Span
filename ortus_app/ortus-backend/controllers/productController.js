const Product = require("../models/Product");
const { uploadBuffer } = require("../utils/cloudinaryUpload");

const parseSizes = (raw) => {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw;
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
};

const getAllProducts = async (req, res) => {
  try {
    const { category } = req.query;
    const filter = {};
    if (category) filter.category = category;
    const products = await Product.find(filter).sort({ createdAt: -1 });
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createProduct = async (req, res) => {
  try {
    if (req.user.role !== "manager") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { name, description, category, price } = req.body;
    const sizes = parseSizes(req.body.sizes);

    if (!name || !price) {
      return res
        .status(400)
        .json({ message: "Название и цена обязательны" });
    }

    const files = req.files || [];
    const images = [];
    for (const file of files) {
      const uploaded = await uploadBuffer(file.buffer, {
        folder: "ortus/products",
        resource_type: "image",
        originalname: file.originalname,
      });
      images.push(uploaded.secure_url);
    }

    const product = await Product.create({
      name,
      description,
      category,
      price: Number(price),
      sizes,
      images,
    });

    res.status(201).json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateProduct = async (req, res) => {
  try {
    if (req.user.role !== "manager") {
      return res.status(403).json({ message: "Access denied" });
    }

    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    const { name, description, category, price } = req.body;
    const sizes = parseSizes(req.body.sizes);

    if (name) product.name = name;
    if (description !== undefined) product.description = description;
    if (category) product.category = category;
    if (price !== undefined) product.price = Number(price);
    if (req.body.sizes !== undefined) product.sizes = sizes;

    if (req.files && req.files.length) {
      const images = [];
      for (const file of req.files) {
        const uploaded = await uploadBuffer(file.buffer, {
          folder: "ortus/products",
          resource_type: "image",
          originalname: file.originalname,
        });
        images.push(uploaded.secure_url);
      }
      product.images = images;
    }

    await product.save();
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteProduct = async (req, res) => {
  try {
    if (req.user.role !== "manager") {
      return res.status(403).json({ message: "Access denied" });
    }

    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    await product.deleteOne();
    res.json({ message: "Product deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getAllProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
};
