
classdef WindTurbine < eNode  
   
   properties (SetAccess = protected)
      id                
      mode              % 'autonomous', 'DSP', 'theWorld'
      strategyType      % 'tariffdrivenLP', 'tariffdrivenLP',
      IDandNetworkInfo  % information such as GPS data, contact details, the Automation Server connection details,...  
      Model             % parameters to describe the model
      Schedule          % schedules, e.g. comfort bound definitions (sampled at 1h)
      StoredData        % proprietary time series class instances to store the prediction, schedule and historical data information relative to the current time instant
      OptimParams       % optimization parameters, such as sampling time, horizon length,...
      OptimProblem      % oprimization problem, which is constructed based on information from Model and OptimParams
      currentTime    
      optimResults
   end
   
   properties(Constant)
      avStrategyTypes = {'TimeSlotOptimization'};
   end
      
   methods      
      % Constructor
      function WindTurbine = WindTurbine( XML, scheduleXML, currentTime, OptimParams, predictions, measures )
%          %          set Current Time
%          if nargin >= 2
%             SolarPanel.SetCurrentTime(currentTime);
%          else
%             SolarPanel.SetCurrentTime(0);
%          end
            % Read configuration from XML
%             if isstruct(XML)
%                def.eNode = XML;
%             else
%                def = util.xml2struct(XML);
%                %def = xml2struct(XML);
%             end

        % With the actual schema, change the driectory is needed
            cd ../Utils;
            def = xml2struct(XML);
            
            WindTurbine.id = def.eNode.GeneralInformation.XMS_ID.Text;
          
            WindTurbine.IDandNetworkInfo.VirtualDataPoints = [];
            WindTurbine.IDandNetworkInfo.XMS_ID = [];
            WindTurbine.IDandNetworkInfo.XMS_info = [];
            
            WindTurbine.Model.Params.type = 'WindTurbine';
            
%           Here we read the model parameters of our Wind Turbine model
%           Vcuton:
%           Vcutoff:
%           FreqPowerCurve:
%           nPW:
%           MaxPW:
%           Ploss_off:
%           Ploss_on:
%           Eff_hl:
%           Eff_fl:
%           MinWindPW_On:
%           MinWindPW_av:

            WindTurbine.Model.Params.Vcuton = str2num(def.eNode.Model.Vcuton.Text);
            WindTurbine.Model.Params.Vcutoff = str2num(def.eNode.Model.Vcutoff.Text);
            
            WindTurbine.Model.Params.FreqPowerCurve = str2num(def.eNode.Model.FreqPowerCurve.Text); % Our freqPowerCurve
            
            WindTurbine.Model.Params.nPW = str2num(def.eNode.Model.nPW.Text);
            WindTurbine.Model.Params.MaxPW = str2num(def.eNode.Model.MaxPW.Text);
            WindTurbine.Model.Params.Ploss_off = str2num(def.eNode.Model.Ploss_off.Text);
            WindTurbine.Model.Params.Ploss_on = str2num(def.eNode.Model.Ploss_on.Text);
            WindTurbine.Model.Params.Eff_hl = str2num(def.eNode.Model.Eff_hl.Text);
            WindTurbine.Model.Params.Eff_fl = str2num(def.eNode.Model.Eff_fl.Text);
            WindTurbine.Model.Params.MinWindPW_On = str2num(def.eNode.Model.MinWindPW_On.Text);
            WindTurbine.Model.Params.MinWindPW_av = str2num(def.eNode.Model.MinWindPW_av.Text);
            % if( isfield( def.eNode.Model, 'FreqEuroCurve' ) )
                WindTurbine.Model.Params.FreqEuroCurve = str2num(def.eNode.Model.FreqEuroCurve.Text); % Our euroFreqCurve
            % end
            WindTurbine.OptimParams.beta=str2num(def.eNode.OptimizationParameters.beta.Text);
            WindTurbine.OptimParams.PriceCutoff = str2num(def.eNode.OptimizationParameters.PriceCutoff.Text);
            WindTurbine.OptimParams.Incentivemin = str2num(def.eNode.OptimizationParameters.Incentivemin.Text);
            WindTurbine.OptimParams.Incentivemax = str2num(def.eNode.OptimizationParameters.Incentivemax.Text);
            WindTurbine.Model.Interface.inputs = {'WindSpeed'};
            WindTurbine.Model.Interface.outputs = {'GeneratedPower'};
            
            WindTurbine.OptimParams.horizon = OptimParams.horizon;
            WindTurbine.OptimParams.tSample = OptimParams.tSample;
            WindTurbine.OptimParams.updatePeriod = OptimParams.updatePeriod;

            WindTurbine.StoredData.WindSpeed = predictions.WindSpeed;
            WindTurbine.StoredData.tariff = predictions.tariff;
        
            WindTurbine.OptimProblem.currentSolution.pow = zeros(round(WindTurbine.OptimParams.horizon/WindTurbine.OptimParams.tSample), 1);
            Windturbine.OptimProblem.currentSolution.objval = 0;
            WindTurbine.OptimProblem.currentSolution.gradient = [];
            WindTurbine.OptimProblem.currentSolution.feasibility = 1;       % flag to indicate whether solver was successful
            
            %% Interpolation 
%             step  = 24*60*60*[0:10]/10;
%             Xaxis = WindTurbine.Model.Params.FreqPowerCurve(2,:);
%             Yaxis = WindTurbine.Model.Params.FreqPowerCurve(1,:);
%            % WindTurbine.OptimProblem.interpFPCurve = interp1( Xaxis , Yaxis, step ,'linear', 'extrap');
%              WindTurbine.OptimProblem.interpFPCurve = interp1( Xaxis , Yaxis, step ,'linear', 'extrap');


%             WindTurbine.OptimProblem.step4FreqEuro = [0:0.0001:1]; % amount of values is 500
%             WindTurbine.OptimProblem.interpFreqEuro = interp1(WindTurbine.Model.Params.FreqEuroCurve(2,:),...
%                 WindTurbine.Model.Params.FreqEuroCurve(1,:),...
%                 WindTurbine.OptimProblem.step4FreqEuro,...
%                 'linear', 'extrap');
%              WindTurbine.OptimProblem.aFreqEuroCombo = [ WindTurbine.OptimProblem.interpFreqEuro; WindTurbine.OptimProblem.step4FreqEuro];
%                 
%             %plot(step,SolarPanel.OptimProblem.interpFreqPower,'r',SolarPanel.Model.Params.FreqPowerCurve(1,:),SolarPanel.Model.Params.FreqPowerCurve(2,:),'xb'); % Plot the freqPower curve
%             WindTurbine.OptimProblem.step4FreqPower = [0: 0.5 :5000];    % needs to be the same amount of values as freqPrice
%             WindTurbine.OptimProblem.interpFreqPower = interp1(WindTurbine.Model.Params.FreqPowerCurve(2,:), ...
%                 WindTurbine.Model.Params.FreqPowerCurve(1,:), ...
%                 WindTurbine.OptimProblem.step4FreqPower, ...
%                 'linear', 'extrap');
%             WindTurbine.OptimProblem.aFreqPowerCombo = [ WindTurbine.OptimProblem.interpFreqPower; WindTurbine.OptimProblem.step4FreqPower];
            
      end      % end constructor
      
    function  [SP] = getOptimResult( SP )
    %   This function launches the optimization algorithm
       Results=SolveProblemWTZigor(SP);
       SP.OptimProblem.currentSolution.pow = Results.pow;
       SP.OptimProblem.currentSolution.objval=Results.objval;
       SP.OptimProblem.currentSolution.ProductionPUproposal=Results.ProductionPUproposal;
%        result.pow = SP.OptimProblem.currentSolution.pow;
%        result.objval = SP.OptimProblem.currentSolution.objval;
%        result.ProductionPUproposal=SP.OptimProblem.currentSolution.ProductionPUproposal;
    end
    
    function [ SP ] = setIncitation( SP, incitation )
    %UNTITLED8 Summary of this function goes here
    %   Detailed explanation goes here

       %N = round(SP.OptimParams.horizon / SP.OptimParams.tSample);
       SP=SP
    end
    
    function [outFreq] = getFreqFromEuro( SP, pEuro)
        
%         clear index;
%         index = find( SP.OptimProblem.aFreqEuroCombo(2,:) == pEuro);
%         outFreq = SP.OptimProblem.aFreqEuroCombo( 1, index);
        i1 = length( SP.Model.Params.FreqEuroCurve( 2, :) );
        maxEuro = SP.Model.Params.FreqEuroCurve( 2, i1);
        if pEuro <= maxEuro
            outFreq = interp1(SP.Model.Params.FreqEuroCurve(2,:), SP.Model.Params.FreqEuroCurve(1,:), pEuro, 'linear', 'extrap' );
        else
            i2 = length( SP.Model.Params.FreqEuroCurve( 1, :) );
            maxFreq = SP.Model.Params.FreqEuroCurve( 1, i2);
            fprintf('Impossible to get more power from the WT. Add more WTs or other producers to your Grid.');
            outFreq = maxFreq;
        end
        
    end
    
    function [outPower] = getPowerFromFreq( SP, pFreq )
        
%         clear index;
%         index = find( SP.OptimProblem.aFreqPowerCombo(1,:) == pFreq);
%         outPower = SP.OptimProblem.aFreqPowerCombo( 2, index);
        outPower = interp1(SP.Model.Params.FreqPowerCurve(1,:), SP.Model.Params.FreqPowerCurve(2,:), pFreq, 'linear', 'extrap' );
    end
    
    function [ SP ] = shiftHorizon( SP, scheduleXML, currentTime, predictions, measures )
     SP=SP;
    end
    function [ control ] = getControl( SP )
    %GetControl Summary of this function goes here
    %   Detailed explanation goes here
      control.pow=SP.OptimProblem.currentSolution.ProductionPUproposal;
    end
      
   end      % end methods
   

end      % end classdef
