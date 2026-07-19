%% Reuse existing profiles (same data as Project 2)
hours = 0:23;
load_profile_hourly = [1.2,1.1,1.0,1.0,1.1,1.3,1.8,2.2,2.5,2.8,3.0,3.2, ...
    3.5,3.8,4.0,4.2,4.5,5.0,5.5,5.2,4.5,3.5,2.5,1.6];

I0 = 1e-9; Rs = 0.5; Rsh = 300; n = 1.3;
k = 1.38e-23; q = 1.6e-19; T = 298;
Vt = n*k*T/q;
Iph_ref = 8.5;
irradiance_hourly_real = [0.0,0.0,0.0,0.0,0.0,3.0,83.1,269.85,501.2,682.72, ...
    847.6,939.67,973.1,918.42,825.6,662.55,469.35,241.88,68.12,0.0,0.0,0.0,0.0,0.0];
solar_power_hourly = zeros(1,24);
V_fixed = 0.6;
for h = 1:24
    Iph = Iph_ref * (irradiance_hourly_real(h)/1000);
    I_pv = Iph - I0*(exp(V_fixed/Vt) - 1) - V_fixed/Rsh;
    solar_power_hourly(h) = max(V_fixed * I_pv, 0);
end
solar_power_hourly = solar_power_hourly * 1.2;

battery_capacity = 10;
battery_efficiency = 0.9;
max_charge_rate = 3;
SoC0 = battery_capacity * 0.5;
nH = 24;

%% Illustrative time-of-use tariff (hypothetical, for demonstrating optimization value)
% Not an actual current UAE utility structure — modeled on common TOU designs
tariff_hourly = zeros(1,24);
tariff_hourly(1:6) = 0.15;     % off-peak (midnight-6am): cheap
tariff_hourly(7:15) = 0.25;    % mid-peak (7am-3pm)
tariff_hourly(16:21) = 0.45;   % peak (4pm-9pm): expensive, matches evening demand peak
tariff_hourly(22:24) = 0.15;   % off-peak (10pm-midnight)

%% Equality constraints: power balance each hour
Aeq = zeros(nH, 4*nH);
beq = zeros(nH, 1);
for h = 1:nH
    Aeq(h, h) = -1;
    Aeq(h, nH+h) = 1;
    Aeq(h, 2*nH+h) = 1;
    Aeq(h, 3*nH+h) = -1;
    beq(h) = load_profile_hourly(h) - solar_power_hourly(h);
end

%% Inequality constraints: battery SoC must stay within [0, capacity]
A = zeros(2*nH, 4*nH);
b = zeros(2*nH, 1);
for h = 1:nH
    A(h, 1:h) = battery_efficiency;
    A(h, nH+1:nH+h) = -1;
    b(h) = battery_capacity - SoC0;

    A(nH+h, 1:h) = -battery_efficiency;
    A(nH+h, nH+1:nH+h) = 1;
    b(nH+h) = SoC0;
end

%% Variable bounds
lb = zeros(4*nH, 1);
ub = inf(4*nH, 1);
ub(1:nH) = max_charge_rate;
ub(nH+1:2*nH) = max_charge_rate;

%% Cost vector using hourly TOU tariff
f = zeros(4*nH, 1);
f(2*nH+1 : 3*nH) = tariff_hourly;

%% Solve the optimization problem
options = optimoptions('linprog','Display','none');
[x_opt, cost_opt] = linprog(f, A, b, Aeq, beq, lb, ub, options);
fprintf('Optimized daily cost (TOU tariff): AED %.2f\n', cost_opt);

%% Rule-based dispatch, costed under the same TOU tariff for fair comparison
SoC_rb = zeros(1,nH); SoC_rb(1) = SoC0;
grid_import_rb = zeros(1,nH);
for h = 1:nH
    if h > 1
        SoC_rb(h) = SoC_rb(h-1);
    end
    net_power = solar_power_hourly(h) - load_profile_hourly(h);
    if net_power > 0
        charge_amt = min([net_power, max_charge_rate, battery_capacity - SoC_rb(h)]);
        SoC_rb(h) = SoC_rb(h) + charge_amt * battery_efficiency;
    else
        deficit = -net_power;
        discharge_amt = min([deficit, max_charge_rate, SoC_rb(h)]);
        SoC_rb(h) = SoC_rb(h) - discharge_amt;
        grid_import_rb(h) = deficit - discharge_amt;
    end
end
cost_rulebased_tou = sum(grid_import_rb .* tariff_hourly);
fprintf('Rule-based cost (TOU tariff): AED %.2f\n', cost_rulebased_tou);
fprintf('Optimization advantage: AED %.2f/day (%.1f%%)\n', ...
    cost_rulebased_tou - cost_opt, (cost_rulebased_tou-cost_opt)/cost_rulebased_tou*100);