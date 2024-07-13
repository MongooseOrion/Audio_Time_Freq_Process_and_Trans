function test(testdir, n, code) %˵����ʶ����Խ׶�
%       testdir : �ַ������Ƶ�Ŀ¼���������еĲ��������ļ�
%       n       : �����ļ�������
%       code    : ����˵���˵�ѵ������

for k = 1:n                     % ��ȡÿ���������Ĳ��������ļ�
    file = sprintf('%ss%d.wav', testdir, k);
    [s, fs] = audioread(file);      
        
    v = mfcc(s, fs);            % ���� MFCC's
   
    distmin = inf;       %��ֵ���ô�
    k1 = 0;
   
    for l = 1:length(code)      % ��������ÿһ���뱾�ľ��루ʧ��ȣ�
        d = disteu(v, code{l});   
        dist = sum(min(d,[],2)) / size(d,1);  %�任�õ�һ���������
        disp(dist);
        if dist < distmin  %һ����ֵ��С����ֵ�����������ˡ�
            distmin = dist;
            k1 = l;
        end      
    end
   
    msg = sprintf('Speaker %d matches with speaker %d', k, k1);
    disp(msg);
end
