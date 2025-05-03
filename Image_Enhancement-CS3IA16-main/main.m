function FullImageFilterApp
    % Inisialisasi figure utama
    fig = uifigure('Name', 'Aplikasi Filter Gambar + Analisis', 'Position', [100 100 1350 750]);
    
    % Panel Parameter Filter
    paramPanel = uipanel(fig, 'Title', 'Parameter Filter',...
        'Position', [30 500 300 220]);
    
    % Kontrol Parameter
    % 1. MEDIAN FILTER
    uilabel(paramPanel, 'Text','Median Kernel:', 'Position',[10 170 100 20]);
    medKernel = uidropdown(paramPanel, 'Items', {'3x3','5x5','7x7','9x9','11x11'},...
        'Position',[120 170 80 22], 'Value','3x3',...
        'ValueChangedFcn',@(src,event)updateParams('median',src.Value));

    % 2. MEAN FILTER
    uilabel(paramPanel, 'Text','Mean Kernel:', 'Position',[10 130 100 20]);
    meanKernel = uidropdown(paramPanel, 'Items', {'3x3','5x5','7x7','9x9','11x11'},...
        'Position',[120 130 80 22], 'Value','3x3',...
        'ValueChangedFcn',@(src,event)updateParams('mean',src.Value));

    % 3. GAUSSIAN FILTER
    uilabel(paramPanel, 'Text','Gaussian Kernel:', 'Position',[10 90 100 20]);
    gaussKernel = uidropdown(paramPanel, 'Items', {'3x3','5x5','7x7','9x9','11x11'},...
        'Position',[120 90 80 22], 'Value','3x3',...
        'ValueChangedFcn',@(src,event)updateParams('gaussKernel',src.Value));
    
    uilabel(paramPanel, 'Text','Sigma:', 'Position',[10 50 100 20]);
    gaussSigma = uieditfield(paramPanel, 'numeric',...
        'Position',[120 50 80 22], 'Value',0.5,...
        'Limits',[0.1 5], 'RoundFractionalValues','off',...
        'ValueChangedFcn',@(src,event)updateParams('gaussSigma',src.Value));

    % 4. KONTRAS
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
        350 420 180 200;    % Asli
        550 420 180 200;    % Median
        750 420 180 200;    % Mean
        950 420 180 200;    % FFT+Mask
        350 80 180 200;     % Kontras
        550 80 180 200;     % Gaussian
        750 80 600 300;     % Histogram
        1150 420 80 200     % Mask
    ];
    
    for i = 1:8
        axs(i) = uiaxes(fig, 'Position', positions(i,:));
        title(axs(i), labels{i});
        if i ~= 7  % Hanya matikan axis untuk selain histogram
            axis(axs(i), 'off');
        end
    end
    
    % Variabel Aplikasi
    appData = struct(...
        'original', [],...
        'mask', [],...
        'params', struct(...
            'medianKernel', [3 3],...
            'meanKernel', [3 3],...
            'gaussKernel', [3 3],...
            'gaussSigma', 0.5,...
            'gamma', 1.0...
        )...
    );
    assignin('base', 'appData', appData);

    %% Fungsi Update Parameter
    function updateParams(paramType, value)
        appData = evalin('base', 'appData');
        switch paramType
            case 'median'
                kernel = sscanf(value, '%dx%d');
                appData.params.medianKernel = [kernel(1) kernel(1)];
            
            case 'mean'
                kernel = sscanf(value, '%dx%d');
                appData.params.meanKernel = [kernel(1) kernel(1)];
            
            case 'gaussKernel'
                kernel = sscanf(value, '%dx%d');
                appData.params.gaussKernel = [kernel(1) kernel(1)];
            
            case 'gaussSigma'
                appData.params.gaussSigma = value;
            
            case 'gamma'
                appData.params.gamma = value;
        end
        assignin('base', 'appData', appData);
    end

    %% Fungsi Upload Gambar
    function uploadImage()
        [f, p] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'});
        if isequal(f, 0), return; end
        img = im2gray(imread(fullfile(p, f)));
        appData = evalin('base', 'appData');
        appData.original = img;
        assignin('base', 'appData', appData);
        
        imshow(img, 'Parent', axs(1));
        updateHistogram(img);
    end

    %% Fungsi Upload Mask
    function uploadMask()
        [f, p] = uigetfile('*.png', 'Pilih File Mask');
        if isequal(f, 0), return; end
        mask = im2gray(imread(fullfile(p, f)));
        appData = evalin('base', 'appData');
        appData.mask = double(mask > 0);
        assignin('base', 'appData', appData);
        
        imshow(mask, 'Parent', axs(8));
    end

    %% Fungsi Proses Utama
    function prosesSemua()
        appData = evalin('base', 'appData');
        if isempty(appData.original)
            uialert(fig, 'Upload gambar terlebih dahulu!', 'Peringatan');
            return;
        end
        
        % Ekstrak parameter
        params = appData.params;
        orig = appData.original;
        mse_values = zeros(5,1);
        
        % 1. MEDIAN FILTER
        med = medfilt2(orig, params.medianKernel);
        imshow(med, 'Parent', axs(2));
        mse_values(1) = immse(orig, med);
        
        % 2. MEAN FILTER
        mean_kernel = fspecial('average', params.meanKernel);
        mean_filtered = imfilter(orig, mean_kernel);
        imshow(mean_filtered, 'Parent', axs(3));
        mse_values(2) = immse(orig, mean_filtered);
        
        % 3. FFT + MASK
        F = fftshift(fft2(double(orig)));
        F_filtered = F .* appData.mask;
        fft_img = uint8(255 * mat2gray(real(ifft2(ifftshift(F_filtered)))));
        imshow(fft_img, 'Parent', axs(4));
        mse_values(3) = immse(orig, fft_img);
        
        % 4. KONTRAS ADJUSTMENT
        kontras_img = imadjust(fft_img, [],[], params.gamma);
        imshow(kontras_img, 'Parent', axs(5));
        mse_values(4) = immse(orig, kontras_img);
        
        % 5. GAUSSIAN FILTER
        gauss_kernel = fspecial('gaussian', params.gaussKernel, params.gaussSigma);
        gauss_img = imfilter(kontras_img, gauss_kernel);
        imshow(gauss_img, 'Parent', axs(6));
        mse_values(5) = immse(orig, gauss_img);
        
        % Update Histogram dan MSE
        updateHistogram(gauss_img);
        updateMSE(mse_values);
    end

    %% Fungsi Bantu Histogram
    function updateHistogram(img)
        % Konversi ke uint8 jika belum
        if ~isa(img, 'uint8')
            img = im2uint8(img);
        end
        
        % Bersihkan axes sebelum plot baru
        cla(axs(7));
        
        % Buat histogram dengan bin edges tepat
        histogram(axs(7), img(:), 'BinEdges', -0.5:1:255.5,...
            'FaceColor', [0.3 0.3 0.3],...
            'EdgeColor', 'none');
        
        % Konfigurasi tampilan
        xlim(axs(7), [0 255]);
        axs(7).XAxis.TickValues = 0:50:255;
        axs(7).YAxis.Exponent = 0;
        xlabel(axs(7), 'Intensitas');
        ylabel(axs(7), 'Frekuensi');
        title(axs(7), 'Histogram Hasil Akhir');
        grid(axs(7), 'on');
    end

    %% Fungsi Update MSE
    function updateMSE(values)
        % Hapus anotasi sebelumnya
        delete(findall(fig, 'Type', 'Textbox'));
        
        % Buat anotasi baru
        annotation(fig, 'textbox',...
            [0.65 0.92 0.3 0.06],...
            'String', sprintf([...
                'MSE:\n'...
                'Median: %.2f | Mean: %.2f\n'...
                'FFT+Mask: %.2f | Kontras: %.2f\n'...
                'Gaussian: %.2f'],...
                values(1), values(2), values(3), values(4), values(5)),...
            'FontSize', 12,...
            'EdgeColor', 'none');
    end
end
