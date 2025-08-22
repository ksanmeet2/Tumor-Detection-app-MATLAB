classdef TumorDetectionApp < matlab.apps.AppBase
    % Medical Image Accessibility App for Tumor Detection
    % Features: Upload MRI, Tumor Heatmap, Tumor Staging, Text-to-Speech, Accessibility

    properties (Access = public)
        UIFigure            matlab.ui.Figure
        UploadButton        matlab.ui.control.Button
        Axes                matlab.ui.control.UIAxes
        ResultLabel         matlab.ui.control.Label
        HeatmapButton       matlab.ui.control.Button
        TTSButton           matlab.ui.control.Button
        TumorStageLabel     matlab.ui.control.Label
    end

    properties (Access = private)
        img                 % MRI image
        tumorMask           % Detected tumor region
        tumorArea           % Area of tumor
    end

    methods (Access = private)

        function uploadImage(app)
            [file,path] = uigetfile({'*.jpg;*.png;*.jpeg;*.tif','Image Files'});
            if isequal(file,0)
                return;
            end
            app.img = imread(fullfile(path,file));
            imshow(app.img,'Parent',app.Axes);
            app.ResultLabel.Text = 'Image uploaded. Click "Generate Heatmap".';
        end

        function generateHeatmap(app)
            if isempty(app.img)
                app.ResultLabel.Text = 'Please upload an image first!';
                return;
            end

            grayImg = rgb2gray(app.img);
            thresh = prctile(grayImg(:),99);   % top 1% intensity threshold
            app.tumorMask = grayImg > thresh;

            % Clean the mask
            app.tumorMask = bwareaopen(app.tumorMask, 50);

            % Calculate tumor area
            app.tumorArea = sum(app.tumorMask(:));

            % Show heatmap overlay
            imshow(app.img,'Parent',app.Axes); hold(app.Axes,'on');
            h = imshow(labeloverlay(grayImg, app.tumorMask,'Colormap','autumn','Transparency',0.5));
            hold(app.Axes,'off');

            % Tumor staging (simple scale)
            if app.tumorArea < 500
                stage = "Stage I - Small";
            elseif app.tumorArea < 2000
                stage = "Stage II - Moderate";
            elseif app.tumorArea < 5000
                stage = "Stage III - Large";
            else
                stage = "Stage IV - Very Large";
            end

            app.TumorStageLabel.Text = ['Tumor Stage: ' char(stage)];
            app.ResultLabel.Text = 'Heatmap generated successfully.';
        end

        function speakResult(app)
            if isempty(app.tumorMask)
                app.ResultLabel.Text = 'No analysis yet!';
                return;
            end
            str = [app.TumorStageLabel.Text, '. Tumor area detected: ', num2str(app.tumorArea), ' pixels.'];
            NET.addAssembly('System.Speech');
            obj = System.Speech.Synthesis.SpeechSynthesizer;
            Speak(obj, str);
        end
    end

    methods (Access = private)

        % Button pushed function: UploadButton
        function UploadButtonPushed(app, event)
            uploadImage(app);
        end

        % Button pushed function: HeatmapButton
        function HeatmapButtonPushed(app, event)
            generateHeatmap(app);
        end

        % Button pushed function: TTSButton
        function TTSButtonPushed(app, event)
            speakResult(app);
        end
    end

    methods (Access = public)

        function app = TumorDetectionApp
            % Create and configure components
            createComponents(app);
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end

    methods (Access = private)

        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'Tumor Detection App';

            % Create Axes
            app.Axes = uiaxes(app.UIFigure);
            title(app.Axes, 'MRI Image / Heatmap')
            app.Axes.Position = [50 120 400 300];

            % Create Upload Button
            app.UploadButton = uibutton(app.UIFigure, 'push');
            app.UploadButton.Text = 'Upload MRI';
            app.UploadButton.Position = [480 360 120 30];
            app.UploadButton.ButtonPushedFcn = createCallbackFcn(app, @UploadButtonPushed, true);

            % Create Heatmap Button
            app.HeatmapButton = uibutton(app.UIFigure, 'push');
            app.HeatmapButton.Text = 'Generate Heatmap';
            app.HeatmapButton.Position = [480 310 120 30];
            app.HeatmapButton.ButtonPushedFcn = createCallbackFcn(app, @HeatmapButtonPushed, true);

            % Create TTS Button
            app.TTSButton = uibutton(app.UIFigure, 'push');
            app.TTSButton.Text = 'Speak Result';
            app.TTSButton.Position = [480 260 120 30];
            app.TTSButton.ButtonPushedFcn = createCallbackFcn(app, @TTSButtonPushed, true);

            % Create Result Label
            app.ResultLabel = uilabel(app.UIFigure);
            app.ResultLabel.Text = 'Upload an image to begin.';
            app.ResultLabel.Position = [50 60 500 30];
            app.ResultLabel.FontSize = 14;

            % Create Tumor Stage Label
            app.TumorStageLabel = uilabel(app.UIFigure);
            app.TumorStageLabel.Text = 'Tumor Stage: Not detected';
            app.TumorStageLabel.Position = [50 20 400 30];
            app.TumorStageLabel.FontSize = 14;

            % Show the UIFigure
            app.UIFigure.Visible = 'on';
        end
    end
end
