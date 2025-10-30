function uart_vibration_gui_xyz
    % UART Vibration Monitor
    % Time domain (g), Frequency domain (FFT), Raw LSB
    % Layout: กราฟซ้าย 70% + Control Panel ขวา 20%

    % Parameters
    Fs   = 1440;   % sample rate (Hz)
    Nfft = 256;    % FFT window size
    f_lowcut = 10; % cutoff frequency (Hz)
    LSB_per_g = 256; % scale factor
    running = false;
    port = [];      % serial port object
    x_data = []; y_data = []; z_data = [];
    x_raw_data = []; y_raw_data = []; z_raw_data = [];

    % Thresholds (g)
    thresholdX = 0.01; 
    thresholdY = 0.01; 
    thresholdZ = 0.01; 

    % --- Figure ---
    fig = figure('Name','UART Vibration Monitor','Position',[100 100 1400 800]);

    % --- Main layout: กราฟ (ซ้าย 70%) ---
    t = tiledlayout(fig,4,2,'TileSpacing','compact','Padding','compact',...
                    'Position',[0.05 0.05 0.7 0.9]);

    % Time domain X
    ax1 = nexttile(t,1); hold(ax1,'on'); grid(ax1,'on');
    hX = plot(ax1,nan,nan,'r');
    xlabel(ax1,'Sample'); ylabel(ax1,'X (g)');
    hTitleX = title(ax1,'Time Domain X'); ylim(ax1,[-1.2 1.2]);

    % FFT X
    ax2 = nexttile(t,2); hold(ax2,'on'); grid(ax2,'on');
    hFFT_X = plot(ax2,nan,nan,'r');
    xlabel(ax2,'Frequency (Hz)'); ylabel(ax2,'Mag (g)');
    title(ax2,'FFT X'); xlim(ax2,[0 Fs/2]);

    % Time domain Y
    ax3 = nexttile(t,3); hold(ax3,'on'); grid(ax3,'on');
    hY = plot(ax3,nan,nan,'g');
    xlabel(ax3,'Sample'); ylabel(ax3,'Y (g)');
    hTitleY = title(ax3,'Time Domain Y'); ylim(ax3,[-1.2 1.2]);

    % FFT Y
    ax4 = nexttile(t,4); hold(ax4,'on'); grid(ax4,'on');
    hFFT_Y = plot(ax4,nan,nan,'g');
    xlabel(ax4,'Frequency (Hz)'); ylabel(ax4,'Mag (g)');
    title(ax4,'FFT Y'); xlim(ax4,[0 Fs/2]);

    % Time domain Z
    ax5 = nexttile(t,5); hold(ax5,'on'); grid(ax5,'on');
    hZ = plot(ax5,nan,nan,'y');
    xlabel(ax5,'Sample'); ylabel(ax5,'Z (g)');
    hTitleZ = title(ax5,'Time Domain Z'); ylim(ax5,[-1.2 1.2]);

    % FFT Z
    ax6 = nexttile(t,6); hold(ax6,'on'); grid(ax6,'on');
    hFFT_Z = plot(ax6,nan,nan,'y');
    xlabel(ax6,'Frequency (Hz)'); ylabel(ax6,'Mag (g)');
    title(ax6,'FFT Z'); xlim(ax6,[0 Fs/2]);

    % Raw LSB (เล็กลง ใช้ 1 แถวเต็ม)
    ax7 = nexttile(t,[1 2]); hold(ax7,'on'); grid(ax7,'on');
    hXraw = plot(ax7,nan,nan,'r');
    hYraw = plot(ax7,nan,nan,'g');
    hZraw = plot(ax7,nan,nan,'y');
    xlabel(ax7,'Sample'); ylabel(ax7,'Raw (LSB)');
    legend(ax7,{'X raw','Y raw','Z raw'});
    title(ax7,'Time Domain Raw (LSB)'); ylim(ax7,[-330 330]);

    % --- Control Panel ด้านขวา (20%) ---
    ctrlPanel = uipanel(fig,'Title','Controls','FontSize',10,...
        'Position',[0.78 0.1 0.2 0.8]); % [left bottom width height]

    % Dropdown เลือก COM port
    ports = serialportlist("available");
    if isempty(ports), ports = {"COM1"}; end
    uicontrol(ctrlPanel,'Style','text','String','Select Port:',...
              'Units','normalized','Position',[0.1 0.9 0.8 0.05],...
              'HorizontalAlignment','left');
    portDropdown = uicontrol(ctrlPanel,'Style','popupmenu','String',ports,...
              'Units','normalized','Position',[0.1 0.82 0.8 0.07]);

    % ปุ่ม Start
    uicontrol(ctrlPanel,'Style','pushbutton','String','Start',...
              'Units','normalized','Position',[0.1 0.65 0.8 0.08],...
              'Callback',@(~,~)startAcq);

    % ปุ่ม Stop
    uicontrol(ctrlPanel,'Style','pushbutton','String','Stop',...
              'Units','normalized','Position',[0.1 0.55 0.8 0.08],...
              'Callback',@(~,~)stopAcq);

    % ปุ่ม Save Figure
    uicontrol(ctrlPanel,'Style','pushbutton','String','Save Figure',...
              'Units','normalized','Position',[0.1 0.45 0.8 0.08],...
              'Callback',@(~,~)saveFig);

    % --- Nested functions ---
    function startAcq
        running = true;
        selectedPort = ports{get(portDropdown,'Value')};
        port = serialport(selectedPort,115200);
        flush(port);
        disp("UART Connected on " + selectedPort);

        while running && isvalid(fig)
            if port.NumBytesAvailable > 0
                data = read(port, port.NumBytesAvailable, "uint8");
                startIdx = find(data == hex2dec('AA'), 1);

                if ~isempty(startIdx) && length(data) >= startIdx + 6
                    if data(startIdx+7) == hex2dec('55')
                        % Decode little-endian
                        x_raw = typecast(uint16(data(startIdx+1)) + ...
                                         bitshift(uint16(data(startIdx+2)),8),'int16');
                        y_raw = typecast(uint16(data(startIdx+3)) + ...
                                         bitshift(uint16(data(startIdx+4)),8),'int16');
                        z_raw = typecast(uint16(data(startIdx+5)) + ...
                                         bitshift(uint16(data(startIdx+6)),8),'int16');

                        % Append raw
                        x_raw_data = [x_raw_data, double(x_raw)];
                        y_raw_data = [y_raw_data, double(y_raw)];
                        z_raw_data = [z_raw_data, double(z_raw)];

                        % Append converted to g
                        x_data = [x_data, double(x_raw)/LSB_per_g];
                        y_data = [y_data, double(y_raw)/LSB_per_g];
                        z_data = [z_data, double(z_raw)/LSB_per_g];

                        % --- Update plots ---
                        set(hX,'XData',1:length(x_data),'YData',x_data);
                        set(hY,'XData',1:length(y_data),'YData',y_data);
                        set(hZ,'XData',1:length(z_data),'YData',z_data);

                        set(hTitleX,'String',sprintf('Time Domain X (Current = %.3f g)', x_data(end)));
                        set(hTitleY,'String',sprintf('Time Domain Y (Current = %.3f g)', y_data(end)));
                        set(hTitleZ,'String',sprintf('Time Domain Z (Current = %.3f g)', z_data(end)));

                        set(hXraw,'XData',1:length(x_raw_data),'YData',x_raw_data);
                        set(hYraw,'XData',1:length(y_raw_data),'YData',y_raw_data);
                        set(hZraw,'XData',1:length(z_raw_data),'YData',z_raw_data);

                        % --- FFT update ---
                        if length(x_data) >= Nfft
                            n = 0:Nfft-1;
                            win = 0.5 * (1 - cos(2*pi*n/(Nfft-1)));
                            f = Fs*(0:(Nfft/2))/Nfft;

                            % FFT X
                            segX = x_data(end-Nfft+1:end);
                            P1x = abs(fft(segX .* win)/Nfft);
                            P1x = P1x(1:Nfft/2+1);
                            if numel(P1x) > 2, P1x(2:end-1) = 2*P1x(2:end-1); end
                            P1x(f < f_lowcut) = 0;
                            set(hFFT_X,'XData',f,'YData',P1x);

                            for k = 1:length(f)
                                if P1x(k) > thresholdX
                                    fprintf("⚠️ X-axis magnitude at %.1f Hz = %.3f g\n", f(k), P1x(k));
                                end
                            end

                            % FFT Y
                            segY = y_data(end-Nfft+1:end);
                            P1y = abs(fft(segY .* win)/Nfft);
                            P1y = P1y(1:Nfft/2+1);
                            if numel(P1y) > 2, P1y(2:end-1) = 2*P1y(2:end-1); end
                            P1y(f < f_lowcut) = 0;
                            set(hFFT_Y,'XData',f,'YData',P1y);

                            for k = 1:length(f)
                                if P1y(k) > thresholdY
                                    fprintf("⚠️ Y-axis magnitude at %.1f Hz = %.3f g\n", f(k), P1y(k));
                                end
                            end

                            % FFT Z
                            segZ = z_data(end-Nfft+1:end);
                            P1z = abs(fft(segZ .* win)/Nfft);
                            P1z = P1z(1:Nfft/2+1);
                            if numel(P1z) > 2, P1z(2:end-1) = 2*P1z(2:end-1); end
                            P1z(f < f_lowcut) = 0;
                            set(hFFT_Z,'XData',f,'YData',P1z);

                            for k = 1:length(f)
                                if P1z(k) > thresholdZ
                                    fprintf("⚠️ Z-axis magnitude at %.1f Hz = %.3f g\n", f(k), P1z(k));
                                end
                            end
                        end

                        drawnow limitrate;
                    end
                end
            end
            pause(0.01);
        end
        clear port;
    end

    function stopAcq
        running = false;
        if ~isempty(port) && isvalid(port)
            clear port;
            disp("UART Disconnected.");
        end
    end

    function saveFig
        [file,path] = uiputfile('vibration_plot.png','Save Figure As');
        if ischar(file)
            exportgraphics(fig, fullfile(path,file));
            disp("Figure saved to " + fullfile(path,file));
        end
    end
end
