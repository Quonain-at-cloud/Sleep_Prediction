const path = require('path');
const fs = require('fs-extra');
const logger = require('./logger');

/**
 * Uploads a file to the local filesystem
 * @param {Object} file - Multer file object
 * @returns {Promise<Object>} - Object containing file information
 */
const uploadImage = async (file) => {
  try {
    if (!file) {
      throw new Error('No file provided for upload');
    }

    // In a production environment, you would upload to a cloud provider here
    // For now, we'll just return the local file path
    const fileUrl = `/uploads/profile-images/${file.filename}`;
    
    logger.info(`File uploaded successfully: ${file.filename}`);
    
    return {
      url: fileUrl,
      path: file.path,
      filename: file.filename,
      mimetype: file.mimetype,
      size: file.size
    };
  } catch (error) {
    logger.error(`Error uploading file: ${error.message}`, { error });
    throw error;
  }
};

/**
 * Deletes a file from the local filesystem
 * @param {string} filePath - Path to the file to delete
 * @returns {Promise<boolean>} - True if deletion was successful
 */
const deleteFile = async (filePath) => {
  try {
    if (!filePath) return true; // Nothing to delete
    
    await fs.unlink(filePath);
    logger.info(`File deleted successfully: ${filePath}`);
    return true;
  } catch (error) {
    // Don't throw error if file doesn't exist
    if (error.code === 'ENOENT') {
      logger.warn(`File not found for deletion: ${filePath}`);
      return true;
    }
    
    logger.error(`Error deleting file: ${error.message}`, { error });
    throw error;
  }
};

/**
 * Deletes a file by its URL (extracts filename from URL)
 * @param {string} fileUrl - URL of the file to delete
 * @returns {Promise<boolean>} - True if deletion was successful
 */
const deleteFileByUrl = async (fileUrl) => {
  if (!fileUrl) return true;
  
  try {
    const filename = path.basename(fileUrl);
    const filePath = path.join(__dirname, '../../uploads/profile-images', filename);
    return await deleteFile(filePath);
  } catch (error) {
    logger.error(`Error deleting file by URL: ${error.message}`, { error });
    throw error;
  }
};

module.exports = {
  uploadImage,
  deleteFile,
  deleteFileByUrl
};
