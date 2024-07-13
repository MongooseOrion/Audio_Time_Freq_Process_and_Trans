function test(testdir, n, code) %说话人识别测试阶段
%       testdir : 字符串名称的目录包含了所有的测试声音文件
%       n       : 测试文件的数量
%       code    : 所有说话人的训练码书

for k = 1:n                     % 读取每个扬声器的测试声音文件
    file = sprintf('%ss%d.wav', testdir, k);
    [s, fs] = audioread(file);      
        
    v = mfcc(s, fs);            % 计算 MFCC's
   
    distmin = inf;       %阈值设置处
    k1 = 0;
   
    for l = 1:length(code)      % 计算其与每一个码本的距离（失真度）
        d = disteu(v, code{l});   
        dist = sum(min(d,[],2)) / size(d,1);  %变换得到一个距离的量
        disp(dist);
        if dist < distmin  %一个阈值，小于阈值，则就是这个人。
            distmin = dist;
            k1 = l;
        end      
    end
   
    msg = sprintf('Speaker %d matches with speaker %d', k, k1);
    disp(msg);
end
