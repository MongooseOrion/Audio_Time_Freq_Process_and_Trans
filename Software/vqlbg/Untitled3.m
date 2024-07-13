% 打开文件
fileID_in = fopen('zm.txt', 'r'); % 输入文件
fileID_out = fopen('1.txt', 'w'); % 输出文件

% 读取文件内容
C = textscan(fileID_in, '%s', 'Delimiter', ';');

% 关闭输入文件
fclose(fileID_in);

% 获取每行数据
data = C{1};

% 循环输出每行数据到输出文件
for i = 1:length(data)
    % 将每行数据按照你需要的格式写入输出文件
    fprintf(fileID_out, '%s\n', data{i});
end

% 关闭输出文件
fclose(fileID_out);
