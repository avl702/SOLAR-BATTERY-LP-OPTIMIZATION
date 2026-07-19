%% Load Profile: Simplified daily electricity demand (24 hours, UAE residential pattern)
hours = 0:23;
% Typical UAE residential load shape: low overnight, rises through day,
% peaks in the evening (AC + lighting overlap)
load_profile_hourly = [1.2,1.1,1.0,1.0,1.1,1.3,1.8,2.2,2.5,2.8,3.0,3.2, ...
    3.5,3.8,4.0,4.2,4.5,5.0,5.5,5.2,4.5,3.5,2.5,1.6]; % kW, illustrative

figure;
plot(hours, load_profile_hourly, '-o');
xlabel('Hour of day'); ylabel('Load (kW)');
title('Simplified Daily Electricity Load Profile');
grid on;

%% Solar Generation Profile (reusing single-diode model logic)
I0 = 1e-9; Rs = 0.5; Rsh = 300; n = 1.3;
k = 1.38e-23; q = 1.6e-19; T = 298;
Vt = n*k*T/q;
Iph_ref = 8.5;

% Real Abu Dhabi hourly irradiance (same data as before)
irradiance_hourly_real = [0.0,0.0,0.0,0.0,0.0,3.0,83.1,269.85,501.2,682.72, ...
    847.6,939.67,973.1,918.42,825.6,662.55,469.35,241.88,68.12,0.0,0.0,0.0,0.0,0.0];

solar_power_hourly = zeros(1,24);
V_fixed = 0.6; % operating near typical MPP voltage

for h = 1:24
    Iph = Iph_ref * (irradiance_hourly_real(h)/1000);
    I_pv = Iph - I0*(exp(V_fixed/Vt) - 1) - V_fixed/Rsh;
    solar_power_hourly(h) = max(V_fixed * I_pv, 0);  % clip negative values to 0
end

% Scale up to represent a small residential solar array (e.g., 10 panels)
num_panels = 1.2;
solar_power_hourly = solar_power_hourly * num_panels;

figure;
plot(hours, load_profile_hourly, '-o', 'DisplayName', 'Load Demand');
hold on;
plot(hours, solar_power_hourly, '-s', 'DisplayName', 'Solar Generation');
legend show;
xlabel('Hour of day'); ylabel('Power (kW)');
title('Load Demand vs Solar Generation');
grid on;

%% Battery Energy Storage System (BESS) Dispatch Simulation
battery_capacity = 10;      % kWh, total usable battery capacity
battery_efficiency = 0.9;   % round-trip efficiency (90%)
max_charge_rate = 3;        % kW, max charge/discharge power limit
SoC = zeros(1,24);          % state of charge, kWh, tracked hour by hour
SoC(1) = battery_capacity * 0.5;  % start at 50% charge

grid_import = zeros(1,24);  % power drawn from grid each hour (kW)
grid_export = zeros(1,24);  % excess power sent back to grid, if any (kW)

for h = 1:24
    net_power = solar_power_hourly(h) - load_profile_hourly(h);

    if h > 1
        SoC(h) = SoC(h-1);  % carry over previous hour's charge
    end

    if net_power > 0
        % Excess solar: charge the battery (up to capacity and rate limit)
        charge_amount = min([net_power, max_charge_rate, battery_capacity - SoC(h)]);
        SoC(h) = SoC(h) + charge_amount * battery_efficiency;
        grid_export(h) = net_power - charge_amount;  % anything battery can't absorb goes to grid
    else
        % Deficit: discharge battery to cover shortfall (up to what's available and rate limit)
        deficit = -net_power;
        discharge_amount = min([deficit, max_charge_rate, SoC(h)]);
        SoC(h) = SoC(h) - discharge_amount;
        grid_import(h) = deficit - discharge_amount;  % remaining shortfall comes from grid
    end
end

figure;
plot(hours, SoC, '-o');
xlabel('Hour of day'); ylabel('Battery State of Charge (kWh)');
title('Battery SoC Over 24 Hours');
grid on;
%% Cost Comparison: With vs Without Battery (ADDC Abu Dhabi tariff)
tariff_rate = 0.268;  % AED per kWh, ADDC residential green-band rate

% Scenario 1: No solar, no battery (grid covers all load)
cost_no_solar = sum(load_profile_hourly) * tariff_rate;

% Scenario 2: Solar only, no battery (excess solar wasted/exported, deficit from grid)
grid_import_no_battery = max(load_profile_hourly - solar_power_hourly, 0);
cost_solar_no_battery = sum(grid_import_no_battery) * tariff_rate;

% Scenario 3: Solar + Battery (using your dispatch simulation results)
cost_solar_with_battery = sum(grid_import) * tariff_rate;

fprintf('\n========== COST COMPARISON (ADDC Tariff: AED %.3f/kWh) ==========\n', tariff_rate);
fprintf('No solar (grid only):        AED %.2f/day\n', cost_no_solar);
fprintf('Solar only (no battery):     AED %.2f/day\n', cost_solar_no_battery);
fprintf('Solar + Battery:             AED %.2f/day\n', cost_solar_with_battery);
fprintf('Savings vs no solar:         AED %.2f/day (%.1f%%)\n', ...
    cost_no_solar - cost_solar_with_battery, ...
    (cost_no_solar - cost_solar_with_battery)/cost_no_solar*100);
fprintf('Additional savings from battery (vs solar-only): AED %.2f/day (%.1f%%)\n', ...
    cost_solar_no_battery - cost_solar_with_battery, ...
    (cost_solar_no_battery - cost_solar_with_battery)/cost_solar_no_battery*100);
fprintf('Annualized savings from battery: AED %.2f/year\n', ...
    (cost_solar_no_battery - cost_solar_with_battery)*365);
fprintf('====================================================================\n');