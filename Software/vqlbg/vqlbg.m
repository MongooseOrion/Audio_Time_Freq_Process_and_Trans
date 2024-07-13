function r = vqlbg(d,k)  %用lbg算法形成码本
a=0;
e = 3/127;                 %误差门限

r1 = fix(mean(floor(d),2));
r = r1;
dpr = 10000000;
for i = 1:log2(k)        % k：所需质心的数目
    dpr = 10000000;
    r = [r+floor(e*r),r-floor(e*r)];
    a=0;
    
    while (1==1)
        z = disteu(d, r);        %欧式距离
        a=a+1;
        [m,ind] = min(z, [], 2);
        t = 0;
        for j = 1:2^i
            
            r(:, j) = fix(mean(d(:, find(ind == j)), 2));
            r(isnan(r)) = 0;
            %disp(length(find(ind == j)));
            x = disteu(d(:, find(ind == j)), r(:, j));
            t1=0;
            for q = 1:length(x)
                t1 = t1 + x(q);
            end
            t = t + t1;
        end
        disp(t);
        if (((dpr - t)/t) < e)
            break;
        else
            dpr = t;
        end
        
    end
    disp(a);
end