function FullImageFilterApp
    % Inisialisasi figure utama
    fig = uifigure('Name', 'Aplikasi Filter Gambar + Analisis', 'Position', [100 100 1350 750]);

    % Panel Parameter Filter
    paramPanel = uipanel(fig, 'Title', 'Parameter Filter', 'Position', [30 500 300 220]);

    % Kontrol Parameter
    uilabel(paramPanel, 'Text','Median Kernel:', 'Position',[10 170 100 20]);
    medKernel = uidropdown(paramPanel, 'Items', {'3x3','5x5','7x7','9x9','11x11'},...
        'Position',[120 170 80 22], 'Value','3x3',...
        'ValueChangedFcn',@(src,event)updateParams('median',src.Value));

    uilabel(paramPanel, 'Text','Mean Kernel:', 'Position',[10 130 100 20]);
    meanKernel = uidropdown(paramPanel, 'Items', {'3x3','5x5','7x7','9x9','11x11'},...
        'Position',[120 130 80 22], 'Value','3x3',...
        'ValueChangedFcn',@(src,event)updateParams('mean',src.Value));

    uilabel(paramPanel, 'Text','Gaussian Kernel:', 'Position',[10 90 100 20]);
    gaussKernel = uidropdown(paramPanel, 'Items', {'3x3','5x5','7x7','9x9','11x11'},...
        'Position',[120 90 80 22], 'Value','3x3',...
        'ValueChangedFcn',@(src,event)updateParams('gaussKernel',src.Value));

    uilabel(paramPanel, 'Text','Sigma:', 'Position',[10 50 100 20]);
    gaussSigma = uieditfield(paramPanel, 'numeric',...
        'Position',[120 50 80 22], 'Value',0.5,...
        'Limits',[0.1 5], 'RoundFractionalValues','off',...
        'ValueChangedFcn',@(src,event)updateParams('gaussSigma',src.Value));

    uilabel(paramPanel, 'Text','Kontras (Gamma):', 'Position',[10 10 100 20]);
    kontrasGamma = uieditfield(paramPanel, 'numeric',...
        'Position',[120 10 80 22], 'Value',1.0,...
        'Limits',[0.1 3], 'RoundFractionalValues','off',...
        'ValueChangedFcn',@(src,event)updateParams('gamma',src.Value));

    % Tombol Upload & Proses
    btnUpload = uibutton(fig, 'Text', 'Upload Gambar Asli',...
        'Position',[30 690 180 30],...
        'ButtonPushedFcn', @(btn,event) uploadImage());

    btnUploadMask = uibutton(fig, 'Text', 'Upload Mask (PNG)',...
        'Position',[230 690 180 30],...
        'ButtonPushedFcn', @(btn,event) uploadMask());

    btnProses = uibutton(fig, 'Text', 'Proses Semua Filter',...
        'Position',[430 690 180 30],...
        'ButtonPushedFcn', @(btn,event) prosesSemua());

    % Area Visualisasi
    axs = gobjects(1, 8);
    labels = {'Asli', 'Median', 'Mean', 'FFT+Mask', 'Kontras', 'Gaussian', 'Histogram', 'Mask'};
    positions = [
        350 420 180 200; 550 420 180 200; 750 420 180 200; 950 420 180 200;
        350 80 180 200;  550 80 180 200;  750 80 600 300;  1150 420 80 200
    ];
    for i = 1:8
        axs(i) = uiaxes(fig, 'Position', positions(i,:));
        title(axs(i), labels{i});
        if i ~= 7, axis(axs(i), 'off'); end
    end

    % Dropdown Histogram
    uilabel(fig, 'Text', 'Lihat Histogram Dari:', 'Position', [750 50 150 20]);
    histDrop = uidropdown(fig, 'Items', {'Gaussian', 'Kontras', 'FFT+Mask', 'Mean', 'Median', 'Original'},...
        'Position', [900 50 120 22], 'Value', 'Gaussian',...
        'ValueChangedFcn', @(src,event) updateHistogramDropdown(src.Value));

    % Variabel Aplikasi
    appData = struct('original', [], 'mask', [], 'params', struct(...
        'medianKernel', [3 3], 'meanKernel', [3 3], 'gaussKernel', [3 3],...
        'gaussSigma', 0.5, 'gamma', 1.0));
    assignin('base', 'appData', appData);

    function updateParams(paramType, value)
        appData = evalin('base', 'appData');
        switch paramType
            case 'median', appData.params.medianKernel = sscanf(value, '%dx%d')';
            case 'mean', appData.params.meanKernel = sscanf(value, '%dx%d')';
            case 'gaussKernel', appData.params.gaussKernel = sscanf(value, '%dx%d')';
            case 'gaussSigma', appData.params.gaussSigma = value;
            case 'gamma', appData.params.gamma = value;
        end
        assignin('base', 'appData', appData);
    end

    function uploadImage()
        [f, p] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'});
        if isequal(f, 0), return; end
        img = im2gray(imread(fullfile(p, f)));
        appData = evalin('base', 'appData');
        appData.original = img;
        assignin('base', 'appData', appData);
        imshow(img, 'Parent', axs(1));
        updateHistogramDropdown('original');
    end

    function uploadMask()
        [f, p] = uigetfile('*.png', 'Pilih File Mask');
        if isequal(f, 0), return; end
        mask = im2gray(imread(fullfile(p, f)));
        appData = evalin('base', 'appData');
        appData.mask = double(mask > 0);
        assignin('base', 'appData', appData);
        imshow(mask, 'Parent', axs(8));
    end

    function prosesSemua()
        appData = evalin('base', 'appData');
        if isempty(appData.original)
            uialert(fig, 'Upload gambar terlebih dahulu!', 'Peringatan'); return;
        end
        params = appData.params;
        orig = appData.original;
        mse_values = zeros(5,1);

        med = medfilt2(orig, params.medianKernel); mse_values(1) = immse(orig, med);
        mean_kernel = fspecial('average', params.meanKernel);
        mean_filtered = imfilter(orig, mean_kernel); mse_values(2) = immse(orig, mean_filtered);

        F = fftshift(fft2(double(orig)));
        F_filtered = F .* appData.mask;
        fft_img = uint8(255 * mat2gray(real(ifft2(ifftshift(F_filtered)))));
        mse_values(3) = immse(orig, fft_img);

        kontras_img = imadjust(fft_img, [],[], params.gamma);
        mse_values(4) = immse(orig, kontras_img);

        gauss_kernel = fspecial('gaussian', params.gaussKernel, params.gaussSigma);
        gauss_img = imfilter(kontras_img, gauss_kernel);
        mse_values(5) = immse(orig, gauss_img);

        imshow(med, 'Parent', axs(2));
        imshow(mean_filtered, 'Parent', axs(3));
        imshow(fft_img, 'Parent', axs(4));
        imshow(kontras_img, 'Parent', axs(5));
        imshow(gauss_img, 'Parent', axs(6));

        appData.median = med;
        appData.mean = mean_filtered;
        appData.fft = fft_img;
        appData.kontras = kontras_img;
        appData.gauss = gauss_img;
        assignin('base', 'appData', appData);

        updateHistogramDropdown(histDrop.Value);
        updateMSE(mse_values);
    end

    function updateHistogramDropdown(selected)
        appData = evalin('base', 'appData');
        switch lower(selected)
            case 'gaussian'
                img = appData.gauss;
            case 'kontras'
                img = appData.kontras;
            case 'fft+mask'
                img = appData.fft;
            case 'mean'
                img = appData.mean;
            case 'median'
                img = appData.median;
            case 'original'
                img = appData.original;
            otherwise
                img = [];
        end

        if isempty(img)
            cla(axs(7));
            title(axs(7), 'Histogram belum tersedia');
        else
            updateHistogram(img);
        end
    end

    function updateHistogram(img)
        if ~isa(img, 'uint8')
            img = im2uint8(mat2gray(img));
        end

        cla(axs(7));

        try
            histogram(axs(7), double(img(:)), ...
                'BinEdges', -0.5:1:255.5, ...
                'FaceColor', [0.2 0.5 0.8], ...
                'EdgeColor', 'none');
            xlim(axs(7), [0 255]);
            axs(7).XAxis.TickValues = 0:50:255;
            axs(7).YAxis.Exponent = 0;
            xlabel(axs(7), 'Intensitas');
            ylabel(axs(7), 'Frekuensi');
            title(axs(7), 'Histogram Gambar Terpilih');
            grid(axs(7), 'on');
        catch ME
            warning("Gagal menampilkan histogram: %s", ME.message);
            title(axs(7), 'Error Histogram');
        end
    end

    function updateMSE(values)
        delete(findall(fig, 'Type', 'Textbox'));
        annotation(fig, 'textbox', [0.65 0.92 0.3 0.06], 'String', sprintf([...
            'MSE:\nMedian: %.2f | Mean: %.2f\nFFT+Mask: %.2f | Kontras: %.2f\nGaussian: %.2f'],...
            values(1), values(2), values(3), values(4), values(5)),...
            'FontSize', 12, 'EdgeColor', 'none');
    end
end
