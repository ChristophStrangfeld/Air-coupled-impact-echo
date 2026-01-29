clear all
close all
clc

%%
%%%%% define the sample rate in Samples per second
sample_rate = 250000;

%%%%% define all x position along the B 70 sleeper with a distance of 5 cm between every measurement point (total length of B 70 sleeper is 260 cm at bottum side)
x_position_in_cm = 5:5:250;

sleeper_number = [2,3,7,8,9,10]; %%%%% available sleepers measured in the lab
excitation_number = [1,2,3]; %%%% three different excitation types were tested #1: 'air-coupled actuation' #2: 'manual impact hammer excitation'; #3: electro-mechanical excitation;

%%%%% first column: number written on the sleeper in the lab, second column: air-coupled actuation, labelled with 1; third column: manual impact hammer excitation labelled with 2; fourth column, electro-mechanical excitation, labelled with 3 if conducted on the corresponding sleeper
excitation_matrix = [2,1,2,3;3,1,2,NaN;7,1,2,3;8,1,2,NaN;9,1,2,NaN;10,1,2,NaN];

%%%%% evaluate all sleepers
for sleeper_index = 1:length(sleeper_number)

    %%%%% generate the folder name for the directory path
    folder_name = (['sleeper_',num2str(sleeper_number(sleeper_index),'%02d') ,'_complete\'])

    %%%%% evalute all types of excitation
    %%%%% only for sleeper number 2 and 7, all three different excitation types are available which is listed in the excitaiton matrix
    number_of_excitation_types = excitation_matrix(find(excitation_matrix(:,1)==sleeper_number(sleeper_index)),2:end);

    for excitation_index = 1:length(number_of_excitation_types(~isnan(number_of_excitation_types)))

        if excitation_number(excitation_index) == 1 %%%%% 'air-coupled actuation'
            subfolder_name = ('air_coupled\');
            excitation_type = 'air coupled excitation';
        elseif excitation_number(excitation_index) == 2 %%%%% 'manual impact hammer excitation'
            subfolder_name = ('manual_impact_hammer\');
            excitation_type = 'manual_impact_hammer';
        elseif excitation_number(excitation_index) == 3 %%%%% electro-mechanical excitation
            subfolder_name = ('electromechanical_impactor\');
            excitation_type = 'electromechanical impactor';
        else
            disp('no assignment to the excitation type. Check folder and subfolder path')
            stop
        end

        %%%%% create required folder path for corresponding data
        data.directory = [folder_name,subfolder_name];

        %%%%% find which are tdms files in the folder
        files = dir(fullfile(data.directory,'*.tdms'));

        %%%%% get the number of files in the directory
        number_of_files = length(files);

        %%%%% read out sleeper number and x-position from the file name for all files
        for file_index = 1:number_of_files
            %%%%% get the file name as a string
            string = files(file_index).name;
            %%%%% extract all numbers from this string as a double
            numbers = str2double(extract(string, digitsPattern));
            %%%%% the second number is the measurement position in cm in x-direction of the sleeper
            x_position_in_cm_unsorted(file_index) = numbers(2);

            %%%%% the first number is the sleeper number
            sleeper_number_crosscheck = numbers(1);

            %%%%% crosscheck to ensure that correct sleeper is considered
            if sleeper_number_crosscheck ~= sleeper_number(sleeper_index)
                disp('folder path or sleeper number incorrect; check the data path')
                stop
            end
        end

        %%%%% sort the x-positions in an increasing order
        [x_position_in_cm_measured, sort_index] = sort(x_position_in_cm_unsorted);

        %%%%%we compute the spectrum for each of the five measurement repetitions and then calculate the mean of the spectra
        for file_index = sort_index %%%%% the x vector is sorted, thus the computation must be processed in the same order so that every spectrum has the correct x position
            %%
            %%%%% below the rail, we could not measure. So we have to fill the spectra matrix with 0 the these positions
            %%%%% the current measurement position devided by 5 gives the index of the measurement position in respect to the total length of the sleeper
            matrix_position = x_position_in_cm_measured(file_index)/5;

            %%%%% read in the tdms file, it is a table inside a cell
            timesignal_cell = tdmsread([data.directory,files(file_index).name], samplerate=sample_rate);

            %%%%% generate data matrix which should be a double; NaN matrix is generated to find errors better later on if the matrix is not filled completely
            timesignal = NaN(size(timesignal_cell{1,1})-[0,1]);

            %%%%% convert the time to a double which is in the format of duration
            time = seconds(timesignal_cell{1,1}.("Time"));

            %%%%% get the corresponding time signal of the five repeated measurements
            timesignal(:,1) = timesignal_cell{1,1}.("Run 1");
            timesignal(:,2) = timesignal_cell{1,1}.("Run 2");
            timesignal(:,3) = timesignal_cell{1,1}.("Run 3");
            timesignal(:,4) = timesignal_cell{1,1}.("Run 4");
            timesignal(:,5) = timesignal_cell{1,1}.("Run 5");

            %%%%% for plots later, a single time signal of manual and air coupled actuation is extracted here
            if sleeper_index ==1 && excitation_index == 1 && file_index == 4  %%%%% factory new sleeper_02
                timesignal_S2_air = timesignal; %%%%% air coupled actuation
                x_pos_S2 = x_position_in_cm_measured(file_index); %%%%% measurement position 4, which is on the sleeper head at X = 20 cm
            elseif sleeper_index ==1 && excitation_index == 2  && file_index == 4 %%%%% factory new sleeper_02
                timesignal_S2_manual = timesignal; %%%%% manual impact hammer
            end

            %%%%% for plots later, a single time signal of manual and air coupled actuation is extracted here
            if sleeper_index ==2 && excitation_index == 1 && file_index == 4  %%%%% factory new sleeper_02
                timesignal_S3_air = timesignal; %%%%% air coupled actuation
                x_pos_S3 = x_position_in_cm_measured(file_index); %%%%% measurement position 4, which is on the sleeper head at X = 20 cm
            elseif sleeper_index ==2 && excitation_index == 2  && file_index == 4 %%%%% factory new sleeper_02
                timesignal_S3_manual = timesignal; %%%%% manual impact hammer
            end

            %%%%% calculate the spectrum for all repeated time signals
            for repetition_index =1:size(timesignal,2)
                %%%%% single spectrum for the entire measurement signal
                %[spectrum, f] = pwelch(timesignal(:,repetition_index),[],[],[],sample_rate);
                %%%%% windowed spectrum. The time signal is defined in 10 sub-signals with an overlap of 50 %
                [spectrum, f] = pwelch(timesignal(:,repetition_index),sample_rate/10,sample_rate/20,[],sample_rate);
                spectra(matrix_position,:,repetition_index) = spectrum;
            end
            %%%%% averaged the windowed FFT over the five repeated measurements, this smoothens the signal even more
            spectrum_averaged(:,matrix_position) = mean(spectra(matrix_position,:,:),3);
        end

        %%%%% combine the spectra of all computed sleepers and all conducted excitation types in one matrix
        spectrum_all(:,:,sleeper_index,excitation_index) = spectrum_averaged;

        %%%%% set the low frequency of the bandpass filter to 5000 Hz
        [~, bandpass_filter_lower_frequency_index] = min(abs(f-5000));
        bandpass_filter_lower_frequency = f(bandpass_filter_lower_frequency_index);

        %%%%% set the high frequency of the bandpass filter to 25000 Hz
        [~, bandpass_filter_upper_frequency_index] = min(abs(f-25000));
        bandpass_filter_upper_frequency = f(bandpass_filter_upper_frequency_index);

        %%%%% find the index for the frequency with the maximum amplitude in the FFT
        [~,index_maximum ]= max(spectrum_averaged(bandpass_filter_lower_frequency_index:bandpass_filter_upper_frequency_index,:));

        %%%%% get the corresponding frequency for the maximum amplitude
        %%%%% we need to add together the index of the maximum search of the bandpass filtered signal plus the index of the minimum frequency -1
        %%%%% to find the right entry in the intinal frequency vector
        maximum_frequencies(:,sleeper_index,excitation_index)  = f(index_maximum + bandpass_filter_lower_frequency_index-1);

        %%%%% replace frequencies below 5kHz to NaN because it is the region below the rail where no measurements are available
        maximum_frequencies(maximum_frequencies<5000) = NaN;

        %%%%% set the low frequency of the bandpass filter to 5000 Hz
        [~, limit_low_frequency_band_energy] = min(abs(f-5000));

        %%%%% set the low frequency of the bandpass filter to 10000 Hz
        [~, limit_medium_frequency_band_energy] = min(abs(f-10000));

        %%%%% set the low frequency of the bandpass filter to 20000 Hz
        [~, limit_high_frequency_band_energy] = min(abs(f-20000));

        %%%%% calculate the power of the FFT for all considered frequencies between 5 kHz to 20 kHz
        total_power(:,sleeper_index,excitation_index) = trapz(spectrum_all(limit_low_frequency_band_energy:limit_high_frequency_band_energy,:,sleeper_index,excitation_index));

        %%%%% calculate the power of the FFT for the frequency band of 5 kHz to 10 kHz
        power_share_normalised_low_frequency_band(:,sleeper_index,excitation_index) = trapz(spectrum_all(limit_low_frequency_band_energy:limit_medium_frequency_band_energy,:,sleeper_index,excitation_index))./total_power(:,sleeper_index,excitation_index)';
        %%%%% calculate the power of the FFT for the frequency band of 10 kHz to 20 kHz
        power_share_normalised_high_frequency_band(:,sleeper_index,excitation_index) = trapz(spectrum_all(limit_medium_frequency_band_energy:limit_high_frequency_band_energy,:,sleeper_index,excitation_index))./total_power(:,sleeper_index,excitation_index)';

    end
end

%% plot a time signal and the corresponding single spectrum for air-coupled and manural actuation for the intact sleeper 2
figure(70)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 18]
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

%%%%% set the low frequency of the bandpass filter to 5000 Hz
[~, t_low] = min(abs(time-0.161))
[~, t_high] = min(abs(time-0.165))

s1=subplot(2,2,1);
plot(time(t_low-1:t_high+1), timesignal_S2_manual(t_low-1:t_high+1,1))
hold on
grid on
xlim([0.161,0.165])
ylim([-0.2,0.5])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
xlabel('Measurement time in s','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Accelerometer amplitude in V','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
plot(0.16152,0.47,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(0.16145,0.475,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s2=subplot(2,2,2);
Fs = 250000;
L = length(timesignal_S2_manual(:,1));
Yfft = fft(timesignal_S2_manual(:,1));
plot(Fs/L*(0:L-1)/1000,abs(Yfft),"LineWidth",1)
hold on
grid on
xlim([5,25])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
xlabel('Frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Amplitude in arbitrary units','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
plot(6.5,1700,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(6.05,1700,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)


s3=subplot(2,2,3);
plot(time(t_low-1:t_high+1), timesignal_S2_air(t_low-1:t_high+1,1))
hold on
grid on
xlim([0.161,0.165])
ylim([-0.05,0.1])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
xlabel('Measurement time in s','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
plot(0.16132,0.093,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(0.16125,0.0933,'c','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s4=subplot(2,2,4);

Fs = 250000;
L = length(timesignal_S2_air(:,1));
Yfft = fft(timesignal_S2_air(:,1));
plot(Fs/L*(0:L-1)/1000,abs(Yfft),"LineWidth",1)
hold on
grid on
xlim([5,25])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
xlabel('Frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
plot(6.5,570,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(6.05,570,'d','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)


x_window = 0.38;
y_window = 0.41;
set(s1,'Position',[0.1 0.57 x_window y_window])
set(s2,'Position',[0.1 0.06 x_window y_window])
set(s3,'Position',[0.59 0.57 x_window y_window])
set(s4,'Position',[0.59 0.06 x_window y_window])


%% plot the frequency band excitation for all sleepers for air-coupled actuation

figure(40)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 25]
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

rail_area_left_x = [30 75 75 30];
rail_area_left_y = [0 0 1 1];
rail_color = [0.75 0.75 0.75];

rail_area_right_x = [180 225 225 180];
rail_area_right_y = [0 0 1 1];

excitation = 1;
s1=subplot(3,2,1);

sleeper =1;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation);
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation);

a = area(x_position_in_cm, Y);
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;
hold on

xlim([0,250])
ylim([0,1])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

set(gca,'XTicklabels',[]);
ylabel('Normalised frequency band energy','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)
legend('5 kHz to 10 kHz','10 kHz to 20 kHz')

s2=subplot(3,2,2);
sleeper =2;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation);
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation);

a = area(x_position_in_cm, Y);
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
set(gca,'XTicklabels',[]);
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s3=subplot(3,2,3);
sleeper =3;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation)
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation)

a = area(x_position_in_cm, Y)
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
set(gca,'XTicklabels',[]);

set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
ylabel('Normalised frequency band energy','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'c','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s4=subplot(3,2,4);

sleeper =4;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation)
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation)

a = area(x_position_in_cm, Y)
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
set(gca,'XTicklabels',[]);
set(gca,'YTicklabels',[]);

set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'d','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s5=subplot(3,2,5);

sleeper =5;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation)
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation)

a = area(x_position_in_cm, Y)
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
xticks([0,50,100,150,200])
set(gca,'XTicklabels',[0,50,100,150,200]);

set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Normalised frequency band energy','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'e','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s6=subplot(3,2,6);

sleeper =6;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation)
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation)

a = area(x_position_in_cm, Y)
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
set(gca,'YTicklabels',[]);

xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'f','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

x_window = 0.44;
y_window = 0.29;
set(s1,'Position',[0.07 0.7 x_window y_window])
set(s3,'Position',[0.07 0.375 x_window y_window])
set(s5,'Position',[0.07 0.05 x_window y_window])
set(s2,'Position',[0.54 0.7 x_window y_window])
set(s4,'Position',[0.54 0.375 x_window y_window])
set(s6,'Position',[0.54 0.05 x_window y_window])


%% plot frequency over energy

figure(41)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
plotstyle.windowsize = [5 5 15 10];
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

power = reshape(power_share_normalised_high_frequency_band,1,[]);
frequency = reshape(maximum_frequencies,1,[]);

plot(power,frequency/1000,'.k','markersize',12)
grid on


xlim([0,1])
ylim([5,20])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

xlabel('Normalised energy of the frequency band 10 kHz to 20 kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Most powerful frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)


%% plot the frequency band excitation for all sleepers for manual actuation

figure(41)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 25]
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

rail_area_left_x = [30 75 75 30];
rail_area_left_y = [0 0 1 1];
rail_color = [0.75 0.75 0.75];

rail_area_right_x = [180 225 225 180];
rail_area_right_y = [0 0 1 1];

excitation = 2;
s1=subplot(3,2,1);

sleeper =1;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation);
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation);

a = area(x_position_in_cm, Y);
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;
hold on

xlim([0,250])
ylim([0,1])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

set(gca,'XTicklabels',[]);
ylabel('Normalised frequency band energy','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)
legend('5 kHz to 10 kHz','10 kHz to 20 kHz')

s2=subplot(3,2,2);
sleeper =2;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation);
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation);

a = area(x_position_in_cm, Y);
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
set(gca,'XTicklabels',[]);
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s3=subplot(3,2,3);
sleeper =3;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation)
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation)

a = area(x_position_in_cm, Y)
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
set(gca,'XTicklabels',[]);

set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
ylabel('Normalised frequency band energy','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'c','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s4=subplot(3,2,4);

sleeper =4;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation)
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation)

a = area(x_position_in_cm, Y)
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
set(gca,'XTicklabels',[]);
set(gca,'YTicklabels',[]);

set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'d','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s5=subplot(3,2,5);

sleeper =5;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation)
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation)

a = area(x_position_in_cm, Y)
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
xticks([0,50,100,150,200])
set(gca,'XTicklabels',[0,50,100,150,200]);

set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Normalised frequency band energy','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'e','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s6=subplot(3,2,6);

sleeper =6;
Y(:,1) = power_share_normalised_low_frequency_band(:,sleeper,excitation)
Y(:,2) = power_share_normalised_high_frequency_band(:,sleeper,excitation)

a = area(x_position_in_cm, Y)
a(1).FaceColor = [1 0 0]
a(1).EdgeColor = 'none';
a(1).FaceAlpha = 0.2;
a(2).FaceColor = [0 1 0]
a(2).EdgeColor = 'none';
a(2).FaceAlpha = 0.2;

hold on

xlim([0,250])
ylim([0,1])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
set(gca,'YTicklabels',[]);

xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

plot(15,0.9,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,0.9,'f','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

x_window = 0.44;
y_window = 0.29;
set(s1,'Position',[0.07 0.7 x_window y_window])
set(s3,'Position',[0.07 0.375 x_window y_window])
set(s5,'Position',[0.07 0.05 x_window y_window])
set(s2,'Position',[0.54 0.7 x_window y_window])
set(s4,'Position',[0.54 0.375 x_window y_window])
set(s6,'Position',[0.54 0.05 x_window y_window])


%% plot the spectrograms for all three excitation types for sleeper 2 and 7

figure(20)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 25]%%%%%Matlab-default-resolution in dpi: 150; Monitor-default-resolution in dpi: 96 (depends on  your monitor setting, check it in your windows display option);
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

rail_area_left_x = [30 75 75 30];
rail_area_left_y = [5 5 20 20];
rail_color = [0.75 0.75 0.75];

rail_area_right_x = [180 225 225 180];
rail_area_right_y = [5 5 20 20];

s1=subplot(3,2,1);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);


surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,2)==1),1)),'edgecolor','none')
xticks([0,50,100,150,200])
xlim([0,250])
ylim([5,20])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-90 -55]);
clim(colobar_limit)

set(gca,'layer','top')
plot3(16,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19.1,10,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s2=subplot(3,2,2);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,2)==1),2)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200])
ylim([5,20])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-80 -50])
clim(colobar_limit)

set(gca,'layer','top')
plot3(16,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19.1,10,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s3=subplot(3,2,3);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,2)==1),3)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200])
ylim([5,20])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-80 -55]);
clim(colobar_limit)

set(gca,'layer','top')
plot3(16,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19.1,10,'c','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s4=subplot(3,2,4);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,7)==1),1)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200])
ylim([5,20])
set(gca,'YTicklabels',[]);
hold on

view(0,90)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

cb = colorbar

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-90 -55]);
clim(colobar_limit)

set(gca,'layer','top')
cb.Label.String = 'power density spectrum in dB';
plot3(16,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19.1,10,'d','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s5=subplot(3,2,5);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,7)==1),2)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200])
ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

cb = colorbar

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-80 -50])
clim(colobar_limit)

set(gca,'layer','top')
cb.Label.String = 'power density spectrum in dB';
plot3(16,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19.1,10,'e','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s6=subplot(3,2,6);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,7)==1),3)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200])
ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

cb = colorbar

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-80 -55]);
clim(colobar_limit)

set(gca,'layer','top')
cb.Label.String = 'power density spectrum in dB';

plot3(16,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19.1,10,'f','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

y_window = 0.29;
set(s1,'Position',[0.07 0.7 0.37 y_window])
set(s2,'Position',[0.07 0.375 0.37 y_window])
set(s3,'Position',[0.07 0.05 0.37 y_window])
set(s4,'Position',[0.49 0.7 0.37 y_window])
set(s5,'Position',[0.49 0.375 0.37 y_window])
set(s6,'Position',[0.49 0.05 0.37 y_window])

%% plot the spectrograms for the first two excitation types for sleeper 3 and 8 and 9

figure(21)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 15]
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

rail_area_left_x = [30 75 75 30];
rail_area_left_y = [5 5 20 20];
rail_color = [0.75 0.75 0.75];

rail_area_right_x = [180 225 225 180];
rail_area_right_y = [5 5 20 20];


s1=subplot(2,3,1);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);


surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,3)==1),1)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200,250])
set(gca,'XTicklabels',[]);
ylim([5,20])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-90 -55]);
clim(colobar_limit)

set(gca,'layer','top')
plot3(25,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(20,19.1,10,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s2=subplot(2,3,2);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,8)==1),1)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200,250])
set(gca,'XTicklabels',[]);

ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
view(0,90)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-90 -55]);
clim(colobar_limit)

set(gca,'layer','top')
plot3(25,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(20,19.1,10,'c','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s3=subplot(2,3,3);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,9)==1),1)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200,250])
set(gca,'XTicklabels',[]);
ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

cb = colorbar

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-90 -55]);
clim(colobar_limit)

set(gca,'layer','top')
cb.Label.String = 'power density spectrum in dB';
plot3(25,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(20,19.1,10,'e','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s4=subplot(2,3,4);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,3)==1),2)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200])
ylim([5,20])
hold on

view(0,90)
xlabel('X position in cm')
ylabel('frequency in kHz')
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-80 -50]);
clim(colobar_limit)

set(gca,'layer','top')
plot3(25,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(20,19.1,10,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s5=subplot(2,3,5);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,8)==1),2)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200])
ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
xlabel('X position in cm')
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-80 -50]);
clim(colobar_limit)

set(gca,'layer','top')
plot3(25,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(20,19.1,10,'d','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)


s6=subplot(2,3,6);
[x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

surf(x_surf,y_surf,pow2db(spectrum_all(:,:,find(ismember(sleeper_number,9)==1),2)),'edgecolor','none')
xlim([0,250])
xticks([0,50,100,150,200])
ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

view(0,90)
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
zlabel('power density spectrum in dB','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

cb = colorbar

c = colormap('hot');
cmap = flipud(c);
colormap(cmap)
colobar_limit = ([-80 -50]);
clim(colobar_limit)

set(gca,'layer','top')
cb.Label.String = 'power density spectrum in dB';

plot3(25,19,10,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(20,19.1,10,'f','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

x_window = 0.25;
y_window = 0.43;
set(s1,'Position',[0.07 0.55 x_window y_window])
set(s2,'Position',[0.345 0.55 x_window y_window])
set(s3,'Position',[0.62 0.55 x_window y_window])
set(s4,'Position',[0.07 0.09 x_window y_window])
set(s5,'Position',[0.345 0.09 x_window y_window])
set(s6,'Position',[0.62 0.09 x_window y_window])

%% plot frequency of highest amplitude for all three excitation types for sleeper 2 and 7

figure(22)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 12]
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

rail_area_left_x = [40 65 65 40];
rail_area_left_y = [5 5 20 20];
rail_color = [0.75 0.75 0.75];

rail_area_right_x = [190 215 215 190];
rail_area_right_y = [5 5 20 20];


s1=subplot(1,2,1);

plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,2)==1),1)/1000,':*b','markersize',12)
hold on
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,2)==1),2)/1000,':sk','markersize',10)
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,2)==1),3)/1000,':.r','markersize',12)
fill([0 0 260 260],[10 20 20 10],'g','edgecolor','none','facealpha',0.2)
fill([0 0 260 260],[5 10 10 5],'r','edgecolor','none','facealpha',0.2)
text(70,10.1,'intact','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color',[0 0.3 0])
text(70,8.1,'damaged','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color','r')

ylim([5,20])
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
grid on
xlim([0,260])
xticks([0,50,100,150,200,250])
ylim([5,20])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)


fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

set(gca,'layer','top')
plot(16,19,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

legend('air-coupled actuation','manual impact-hammer','electromechnically \newlinemounted impactor','location','south','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)


s2=subplot(1,2,2);
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,7)==1),1)/1000,':*b','markersize',12)
hold on
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,7)==1),2)/1000,':sk','markersize',10)
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,7)==1),3)/1000,':.r','markersize',12)
fill([0 0 260 260],[10 20 20 10],'g','edgecolor','none','facealpha',0.2)
fill([0 0 260 260],[5 10 10 5],'r','edgecolor','none','facealpha',0.2)
text(70,10.1,'intact','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color',[0 0.3 0])
text(70,8.1,'damaged','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color','r')

ylim([5,20])
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
grid on
xlim([0,260])
xticks([0,50,100,150,200,250])
ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

set(gca,'layer','top')
plot(16,19,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)


set(s1,'Position',[0.07 0.09 0.43 0.9])
set(s2,'Position',[0.54 0.09 0.43 0.9])

%% plot frequency of highest amplitude for first two excitation types for sleeper 3, 8, 9 and 10

figure(23)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 12]
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

rail_area_left_x = [40 65 65 40];
rail_area_left_y = [5 5 20 20];
rail_color = [0.75 0.75 0.75];

rail_area_right_x = [190 215 215 190];
rail_area_right_y = [5 5 20 20];

s1=subplot(2,2,1);
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,3)==1),1)/1000,':*b','markersize',12)
hold on
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,3)==1),2)/1000,':sk','markersize',10)
fill([0 0 260 260],[10 20 20 10],'g','edgecolor','none','facealpha',0.2)
fill([0 0 260 260],[5 10 10 5],'r','edgecolor','none','facealpha',0.2)
text(30,17.2,'intact','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color',[0 0.3 0])
text(30,5.3,'damaged','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color','r')
ylim([5,20])
grid on
xlim([0,260])
xticks([0,50,100,150,200,250])
set(gca,'XTicklabels',[]);
ylim([5,20])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

set(gca,'layer','top')
plot(16,19,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

legend('air-coupled actuation','manual impact-hammer','location','south','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

s2=subplot(2,2,2);

plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,8)==1),1)/1000,':*b','markersize',12)
hold on
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,8)==1),2)/1000,':sk','markersize',10)
fill([0 0 260 260],[10 20 20 10],'g','edgecolor','none','facealpha',0.2)
fill([0 0 260 260],[5 10 10 5],'r','edgecolor','none','facealpha',0.2)
text(30,17.2,'intact','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color',[0 0.3 0])
text(30,5.3,'damaged','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color','r')

ylim([5,20])
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
grid on
xlim([0,260])
xticks([0,50,100,150,200,250])
ylim([5,20])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

set(gca,'layer','top')
plot(16,19,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s3=subplot(2,2,3);

plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,9)==1),1)/1000,':*b','markersize',12)
hold on
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,9)==1),2)/1000,':sk','markersize',10)
fill([0 0 260 260],[10 20 20 10],'g','edgecolor','none','facealpha',0.2)
fill([0 0 260 260],[5 10 10 5],'r','edgecolor','none','facealpha',0.2)
text(30,17.2,'intact','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color',[0 0.3 0])
text(30,5.3,'damaged','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color','r')

ylim([5,20])
grid on
xlim([0,260])
xticks([0,50,100,150,200,250])
set(gca,'XTicklabels',[]);
ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

set(gca,'layer','top')
plot(16,19,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19,'c','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s4=subplot(2,2,4);

plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,10)==1),1)/1000,':*b','markersize',12)
hold on
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,10)==1),2)/1000,':sk','markersize',10)
fill([0 0 260 260],[10 20 20 10],'g','edgecolor','none','facealpha',0.2)
fill([0 0 260 260],[5 10 10 5],'r','edgecolor','none','facealpha',0.2)
text(30,17.2,'intact','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color',[0 0.3 0])
text(30,5.3,'damaged','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color','r')

ylim([5,20])
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
grid on
xlim([0,260])
xticks([0,50,100,150,200,250])
ylim([5,20])
set(gca,'YTicklabels',[]);
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

set(gca,'layer','top')
plot(16,19,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19,'d','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

x_window = 0.45;
y_window = 0.43;
set(s1,'Position',[0.07 0.56 x_window y_window])
set(s2,'Position',[0.07 0.09 x_window y_window])
set(s3,'Position',[0.54 0.56 x_window y_window])
set(s4,'Position',[0.54 0.09 x_window y_window])

%% plot frequency of highest amplitude for sleeper 2 and 7 for ECNDT 2026

figure(222)
plotstyle.fontsize = 10;
plotstyle.fontname = 'arial';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 10]
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

rail_area_left_x = [40 65 65 40];
rail_area_left_y = [5 5 20 20];
rail_color = [0.75 0.75 0.75];

rail_area_right_x = [190 215 215 190];
rail_area_right_y = [5 5 20 20];

s1=subplot(1,2,1);



plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,2)==1),1)/1000,':*b','markersize',12)
hold on
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,2)==1),2)/1000,':sk','markersize',10)

fill([0 0 255 255],[10 20 20 10],'g','edgecolor','none','facealpha',0.2)
fill([0 0 255 255],[5 10 10 5],'r','edgecolor','none','facealpha',0.2)
text(70,10.2,'intact','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color',[0 0.3 0])
text(70,7.3,'damaged','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color','r')
%title(['Schwelle: ',num2str(sleeper_number(sleeper_index))])

ylim([5,20])
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
grid on
xlim([0,255])
xticks([0,50,100,150,200,250])
ylim([5,20])
%zlim([])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
%plot3(x_position_in_cm,0,maximum_frequencies)

%xlabel('X Position in cm')
%xlabel('X position in cm')
%ylabel('Frequenz in kHz')
ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
%zlabel('Leistungsdichtespektrum in dB')



fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

set(gca,'layer','top')
% load('colormap','cmap')
% colormap(cmap)
% shading flat
% cb = colorbar
%cb.Label.String = 'Leistungsdichtespektrum in dB';
%cb.Label.String = 'power density spectrum in dB';
plot(16,19,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

legend('air-coupled actuation','manual impact-hammer','location','south','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
%title(['Schwelle: ',num2str(sleeper_number(sleeper_index)),'; Anregungsart: ', excitation_type])
%save('colormap','cmap')


s2=subplot(1,2,2);

plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,7)==1),1)/1000,':*b','markersize',12)
hold on
plot(x_position_in_cm,maximum_frequencies(:,find(ismember(sleeper_number,7)==1),2)/1000,':sk','markersize',10)
%legend('Luftgekoppelte Anregung','Manueller Impakt-Hammer','Elektromagnetischer Impaktor','location','south')
%title(['Schwelle: ',num2str(sleeper_number(sleeper_index))])

ylim([5,20])
xlabel('X position in cm','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
grid on
xlim([0,255])
xticks([0,50,100,150,200,250])
ylim([5,20])
set(gca,'YTicklabels',[]);
%zlim([])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
hold on
%plot3(x_position_in_cm,0,maximum_frequencies)

%xlabel('X Position in cm')
%xlabel('X position in cm')
%ylabel('Frequenz in kHz')
%ylabel('frequency in kHz','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
%zlabel('Leistungsdichtespektrum in dB')
fill([0 0 255 255],[10 20 20 10],'g','edgecolor','none','facealpha',0.2)
fill([0 0 255 255],[5 10 10 5],'r','edgecolor','none','facealpha',0.2)
text(70,10.2,'intact','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color',[0 0.3 0])
text(70,7.3,'damaged','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname,'color','r')

fill(rail_area_left_x,rail_area_left_y,rail_color,'EdgeColor','none')
text(50,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
fill(rail_area_right_x,rail_area_right_y,rail_color,'EdgeColor','none')
text(200,12.5,'rail','rotation',90,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)

set(gca,'layer','top')
% load('colormap','cmap')
% colormap(cmap)
% shading flat
% cb = colorbar
%cb.Label.String = 'Leistungsdichtespektrum in dB';
%cb.Label.String = 'power density spectrum in dB';
plot(16,19,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(11,19,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

set(s1,'Position',[0.07 0.11 0.43 0.85])
set(s2,'Position',[0.54 0.11 0.43 0.85])

%% plot the spectrograms for every sleeper and every type of excitation

for sleeper_index = 1:length(sleeper_number)

    %%%%% evalute all types of excitation
    %%%%% only for sleeper number 2 and 7, all three different excitation types are available
    number_of_excitation_types = excitation_matrix(find(excitation_matrix(:,1)==sleeper_number(sleeper_index)),2:end);

    for excitation_index = 1:length(number_of_excitation_types(~isnan(number_of_excitation_types)))
        %%%%% adjusting the limits of the colorbar to the corresponding excitaiton type to improve comparable color plots
        if excitation_number(excitation_index) == 1 %%%%% 'air-coupled actuation'
            subfolder_name = ('Luftgekoppelt\')
            excitation_type = 'Luftgekoppelte Anregung';
            colobar_limit = ([-90 -55]);
        elseif excitation_number(excitation_index) == 2 %%%%% 'manual impact hammer excitation'
            subfolder_name = ('Impakthammer\')
            excitation_type = 'Manueller Impakt-Hammer';
            colobar_limit = ([-80 -50]);
        elseif excitation_number(excitation_index) == 3 %%%%% electro-mechanical excitation
            subfolder_name = ('elektromagnetischer impaktor\')
            excitation_type = 'Elektromagnetischer Impaktor';
            colobar_limit = ([-80 -55]);
        else
            disp('no assignment to the excitation type. Check folder and subfolder path')
            stop
        end

        figure(11)
        plotstyle.fontsize = 10;
        plotstyle.fontname = 'times new roman';
        clf
        figurecontrol =0;
        plotstyle.windowsize = [5 5 15 9]%%%%%Matlab-default-resolution in dpi: 150; Monitor-default-resolution in dpi: 96 (depends on  your monitor setting, check it in your windows display option);
        set(gcf,'Units','centimeters');
        set(gcf,'Position',plotstyle.windowsize);
        set(gcf, 'PaperPositionMode' , 'auto');

        [x_surf, y_surf] = meshgrid(x_position_in_cm,f/1000);

        surf(x_surf,y_surf,pow2db(spectrum_all(:,:,sleeper_index,excitation_index)),'edgecolor','none')
        ylim([5,25])
        %zlim([])
        hold on
        %plot3(x_position_in_cm,0,maximum_frequencies)

        view(0,90)
        %xlabel('X Position in cm')
        xlabel('X position in cm')
        %ylabel('Frequenz in kHz')
        ylabel('frequency in kHz')
        %zlabel('Leistungsdichtespektrum in dB')
        zlabel('power density spectrum in dB')

        cb = colorbar

        c = colormap('hot');
        cmap = flipud(c);
        colormap(cmap)
        %        clim = [colobar_limit]

        clim(colobar_limit)
        %clim([-90 -55])

        set(gca,'layer','top')
        % load('colormap','cmap')
        % colormap(cmap)
        % shading flat
        % cb = colorbar
        %cb.Label.String = 'Leistungsdichtespektrum in dB';
        cb.Label.String = 'power density spectrum in dB';

        %title(['Schwelle: ',num2str(sleeper_number(sleeper_index)),'; Anregungsart: ', excitation_type])
        %save('colormap','cmap')

    end
end


%% plot frequency with most energy along the sleeper axis only for air-coupled and manual impact-hammer actuation
figure(14)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 9]%%%%%Matlab-default-resolution in dpi: 150; Monitor-default-resolution in dpi: 96 (depends on  your monitor setting, check it in your windows display option);
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

for sleeper_index = 1: length(sleeper_number)
    clf
    plot(x_position_in_cm,maximum_frequencies(:,sleeper_index,1)/1000,':*b','markersize',12)
    hold on
    plot(x_position_in_cm,maximum_frequencies(:,sleeper_index,2)/1000,':sk','markersize',10)



    %legend('Luftgekoppelte Anregung','Manueller Impakt-Hammer','location','northwest')
    legend('air-coupled excitation','manual impact hammer','location','northwest')
    %title(['Schwelle: ',num2str(sleeper_number(sleeper_index))])

    ylim([5,25])
    %xlabel('X Position in cm')
    xlabel('X position in cm')
    %ylabel('Frequenz in kHz')
    ylabel('frequency in kHz')
    grid on

end

%% plot a time signal for data in brief
figure(75)
plotstyle.fontsize = 10;
plotstyle.fontname = 'times new roman';
clf
figurecontrol =0;
plotstyle.windowsize = [5 5 15 18]
set(gcf,'Units','centimeters');
set(gcf,'Position',plotstyle.windowsize);
set(gcf, 'PaperPositionMode' , 'auto');

s1=subplot(2,2,1);
plot(time(1:500000), timesignal_S3_manual(1:500000,1))
hold on
grid on
xlim([0,2])
ylim([-2.2,2.2])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
xlabel('Measurement time in s','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Accelerometer amplitude in V','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
plot(0.25,2,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(0.21,2,'a','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s2=subplot(2,2,2);
plot(time(1:500000), timesignal_S3_manual(1:500000,1))
hold on
grid on
grid minor
xlim([0.11,0.16])
ylim([-0.5,.5])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
xlabel('Measurement time in s','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Accelerometer amplitude in V','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
plot(0.115,0.45,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(0.114,0.45,'b','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s3=subplot(2,2,3);
plot(time(1:500000), timesignal_S3_air(1:500000,1))
hold on
grid on
xlim([0,2])
ylim([-0.1,0.05])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
xlabel('Measurement time in s','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Accelerometer amplitude in V','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
plot(0.25,0.043,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(0.21,0.043,'c','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)

s4=subplot(2,2,4);
plot(time(1:500000), timesignal_S3_air(1:500000,1))
hold on
grid on
xlim([0.11,0.16])
ylim([-0.1,0.05])
set(gca,'fontsize',plotstyle.fontsize,'fontname',plotstyle.fontname)
xlabel('Measurement time in s','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
ylabel('Accelerometer amplitude in V','fontsize',plotstyle.fontsize,'FontName',plotstyle.fontname)
plot(0.115,0.043,'marker','o', 'markersize',16,'MarkerEdgeColor','k','MarkerFaceColor','w')
text(0.114,0.043,'d','fontsize',plotstyle.fontsize+4,'fontname',plotstyle.fontname)


x_window = 0.38;
y_window = 0.41;
set(s1,'Position',[0.1 0.57 x_window y_window])
set(s2,'Position',[0.59 0.57 x_window y_window])
set(s3,'Position',[0.1 0.06 x_window y_window])
set(s4,'Position',[0.59 0.06 x_window y_window])
