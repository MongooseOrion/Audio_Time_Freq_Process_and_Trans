% ���ļ�
fileID_in = fopen('zm.txt', 'r'); % �����ļ�
fileID_out = fopen('1.txt', 'w'); % ����ļ�

% ��ȡ�ļ�����
C = textscan(fileID_in, '%s', 'Delimiter', ';');

% �ر������ļ�
fclose(fileID_in);

% ��ȡÿ������
data = C{1};

% ѭ�����ÿ�����ݵ�����ļ�
for i = 1:length(data)
    % ��ÿ�����ݰ�������Ҫ�ĸ�ʽд������ļ�
    fprintf(fileID_out, '%s\n', data{i});
end

% �ر�����ļ�
fclose(fileID_out);
