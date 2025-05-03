Here’s the English version of the GitHub project description for your MATLAB GUI application:

---

## 🎯 MATLAB GUI Application – Digital Image Processing and Quality Evaluation using MSE

### 📌 Overview

This project is a **MATLAB-based GUI application** designed to help users perform **interactive and visual digital image processing**. The application allows users to **upload an original image and a mask**, then apply a variety of **commonly used image filtering techniques**. Each filtered result is evaluated using **MSE (Mean Squared Error)** to assess the image quality compared to the original input.

This tool is suitable for students, researchers, or anyone interested in exploring and comparing different image processing techniques such as **Median Filtering**, **Mean Filtering**, **Gaussian Filtering**, **Fourier Transform with Masking**, and **Contrast Adjustment**.

---

### 🧩 Key Features

* ✅ **Upload Original Image** in `.jpg`, `.png`, or `.bmp` formats
* ✅ **Upload Mask Image** (usually `.png` grayscale or binary mask)
* ✅ **Median Filtering** (non-linear) with selectable kernel sizes (from 3×3 to 19×19)
* ✅ **Mean Filtering** (linear) with adjustable kernel sizes
* ✅ **Gaussian Filtering** with adjustable kernel sizes
* ✅ **Fourier Transform + Masking** for frequency domain filtering
* ✅ **Contrast Adjustment** using MATLAB’s `imadjust`
* ✅ **Automatic Quality Evaluation** using **Mean Squared Error (MSE)**
* ✅ **Histogram Visualization** of original and processed images
* ✅ **User-Friendly GUI** to interactively explore filter effects and results

---

### 🔍 Purpose

* To demonstrate differences between popular image filters
* To support learning of **spatial vs. frequency domain filtering**
* To evaluate filter effectiveness using quantitative MSE metrics

---

### 📸 User Interface Highlights

The GUI displays:

* Original image and each processed result
* Histogram of the original and final filtered image
* MSE values shown for each processing stage
* Dropdown menu for kernel size selection (applies to median, mean, and Gaussian filters)

---

### 🛠️ How to Use

1. Run the main file (e.g., `FullImageFilterApp.m`) in MATLAB
2. Click **"Upload Original Image"** to load an input image
3. Click **"Upload Mask"** to load a mask image (binary preferred)
4. Select the desired **kernel size** from the dropdown
5. Click **"Process All Filters"**
6. View the filtering results, histograms, and MSE values

---

### 📂 Project Structure

FullImageFilterApp.m   % Main GUI application file
mask.png               % Sample mask image
README.md              % Project description (optional)
```

---

### 🧪 Requirements

* MATLAB R2019b or later
* Image Processing Toolbox

---

### 📘 License

This project is released under the MIT License. Feel free to use, modify, or redistribute with attribution.

---

