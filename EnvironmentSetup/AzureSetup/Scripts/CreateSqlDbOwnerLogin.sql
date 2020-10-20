EXECUTE('CREATE USER [' + @Username + '] WITH PASSWORD = ''' + @Password + '''')
EXECUTE('GRANT CONNECT TO [' + @Username + ']')
EXECUTE('ALTER ROLE db_owner ADD MEMBER [' + @Username + ']')