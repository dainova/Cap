$VERBOSE = nil                         ###- supress warnings



# 1   Load regex file  ListRegex, build Union in loop Regex
# 2   Loop 2:  Process all files in dirToSearch
# 3   Loop 3 nested :  Process each line of file for multiple regex's in one pass (result is 2 dim array)
# 4   Loop 4 nested :  Process result array to log all result

#  RegexFile sample format, need 2 rows with  $Tbl  and $Col:
# $TblEncounters
# $ColPatient
# Select
# /*



username = ENV['USERNAME']
dirToSearch = 'C:/Users/'+ username  + '/Dropbox/EduDropBox/XXX/*.sql'
dirToLog =   'C:/Users/'+ username  + '/Dropbox/EduDropBox/XXX/'
FileRegex = 'C:/Users/'+ username  + '/Dropbox/EduDropBox/XXX/ListRegex.txt'



unless Dir.exists? File.dirname(dirToSearch)
  abort (' Config error!!!!!!!!!!  Directory to scan  not exists:   ' + File.dirname(dirToSearch))                                   end
unless Dir.exists? dirToLog
  abort (' Config error!!!!!!!!!!  Directory to log  not exists:   ' + dirToLog)                                                     end
unless File.exists? FileRegex
  abort (' Config error!!!!!!!!!!  File with regex list  not exists:   ' + FileRegex)                                                end

##  regex to mach whild char * for select
w1 =     '\s\*\s'              ##  * FROM  (space left and right)             handles for wild chars single asterisk == means any column
w2 =     '\.\*\s'              ##   .*       table.*
w3 =     '\A\*\s'              ## * Start of line
w4 =     '\s\*\z'              ##  End of line *

wildArray = ['\s\*\s',  '\.\*\s',   '\A\*\s' , '\s\*\z' ]
comArray  = ['select', 'delete' 'update', 'insert', 'alter']



now = Time.now
open(dirToLog +'update_log.txt', 'w') { |f|   f.puts 'Regex|Tag|Status|File|LineNo|Pos|Dir|LineContent|Idx| '+ (Time.now).strftime('%a, %d %b %Y %H:%M:%S').to_s  }            ## header line to log file



f = File.open(FileRegex) or die "Unable to open file..."
RegexArray = File.readlines(FileRegex)
puts '.............. Regexdata1:    ' + RegexArray.length.to_s + '   ' + RegexArray[0].chomp + '    ' + RegexArray[1].chomp  + '.....    last: ' + RegexArray.last.chomp

#RegexData << w1 << w2 << w3 << w4                                                   ##  adding wild chars to regex
puts '.............. Regexdata2: *: ' + RegexArray.length.to_s + '   ' + RegexArray[0].chomp + '    ' + RegexArray[1].chomp  + '.....     last: ' + RegexArray.last.chomp

RegexArray.map! {|a| a.strip.chomp}                      ## remove all spaces and /n

##  check that Input Regex has $Tbl and $Col tags to ID table name/column
tblElement = RegexArray.detect {|e| e[0..3].casecmp('$Tbl') == 0}
unless  tblElement.nil?
  tableName = tblElement[4..-1].downcase      end

colElement = RegexArray.detect {|e| e[0..3].casecmp('$Col') == 0}
unless  tblElement.nil?
  colName = colElement[4..-1].downcase       end

if tableName == '' or colName == '' or tableName.nil? or colName.nil?
  puts 'Error !!!!!!!!!!!!!!! col or  table name is not supplied, use $TblmyTable  or $ColMyPatient format'
  die " Config error!!!!!!!!!!  Check your regex list file,  should include $Tbl and $Col records !!!   Rest are optional"
end
puts '............tableName: .'  + tableName.to_s + '.     colName:.' +  colName.to_s + '.'




#########################\\\\\\ Loop 1 start to union all elements into regex class
regUs = '(?-mix:'                     ## define string var with initial regex expression mix
RegexArray.each  {|val|
  val2 = val
  if val2[0..3].casecmp('$Tbl')   == 0  or  val2[0..3].casecmp('$Col')   == 0   then                   ## cut special $Tbl $Col id for those 2
    #puts '............. String' + val2
    val2 = val2[4..-1]         # cut off $Tbl  $Col identifiers
  end

  if  ["/*", "*/"].include?(val2)          then
    val3 = '\\' + val2[0..0] + '\\' +  val2[1..1]
  else
    if  [ "--"].include?(val2)               then
      val3 = val2
    else val3 = '\b' + val2 + '\b'
    end end


  regUs <<  '(?ix-m:' + val3 + ')|'         ## adding elements to arragy to use for regex union
}

#   addding wild chars in one step after loop
regUs << '(?ix-m:' + w1 + ')|'    +  '(?ix-m:' + w2 + ')|' +    '(?ix-m:' + w3 + ')|' +    '(?ix-m:' + w4 + '))'


puts '.............2a  regU string: ' +   regUs.to_s
regU = Regexp.new(regUs)                        # need regexp class  from string
puts '.............2b  regU : ' +   regU.to_s

######################//// Loop #1  End

# 2   Loop 2:  Process all files in dirToSearch

found = false


#puts 'ryba'

Dir.glob(dirToSearch).each do |file_name|                                                                  #################\\\\\\\ Loop 02    All files in Files (could be recursive if  specified)
  lineNum = 0
  puts '..............file Name:::::::::::' + file_name   ###+ '..  string is = ' + found.to_s



  file2 = File.open(file_name,"r")
  file2.each{|line|                                                                                                                    #################\\\\ Loop 03      Lines in file
    lineNum += 1
    puts
    puts '.....................   Line ' + lineNum.to_s + ' in file ' + file_name + ': ' + line


    result = []
    line.scan(regU) do |x|
      result << [x, Regexp.last_match.offset(0).first]    # 2 dim array with results [ Alpha,4  Bravo,21   Charlie,31
    end

    puts '............. Scan Results  ' + result.length.to_s  +   result.inspect.to_s




    if result.length  > 0  then
      IDX=''            
      hitNum =0
      cmtCount = 0
      result.each {|val|    #################  ------------------------------------------ 4 LOOP start  process result of multi regex for line.
        hitNum += 1
        IDX = lineNum * 1000  + val[1]             ## absolute IDX for while char * to track column/table

        if val[0] == '/*'  then cmtCount += 1
          #puts '.............  cmtCount +1: ' + cmtCount.to_s
        else
        if val[0] == '*/'  then cmtCount -= 1
            #puts '............. cmtCount -1:  ' + cmtCount.to_s
        else
        if val[0] == '--'  then cmtCount  = 100
              #puts '............. cmtCount  Line= ' + cmtCount.to_s
        end end end


        if val[0].downcase == tableName      then     tag = 'Table'
             #puts '....................................Match Table: Value0:' + val[0]	+  '        Tag:' + tag + ' IDX: ' +  IDX.to_s
        else
        if val[0].downcase == colName       then tag = 'Column'
            #puts '....................................Match Colmn: Value0:' + val[0]	 +  '        Tag:' + tag
         else
         if val[0].strip          == '*'           then tag = 'Wild'
	          #puts '.....................................Match Wild: ' + val[0]	 +  '  i: ' + val[1].to_s + '     Tag:' + tag +  ' IDX: ' + IDX.to_s
         else tag =	'Command' ###val[0]
              #puts '............................................Match WHY WHY WHY : Value0:' + val[0]	 +  '        Tag:' + tag
         end end end



         if cmtCount == 0   then status = 'active'  else  status = 'comment'   end

         puts '.............  Hit No: ' + hitNum.to_s      + '     Value: ' +  val[0]  + '     Offset: ' + val[1].to_s + '   Tag: ' + tag + '   Status:  ' + status


        if ["/*", "*/", "--"].include?(val[0])     then                              ## we don't log comments line, easy change if needed to log them.
          #    puts '.............  Comments char: ' + val[0]
          next  ####break out of IF  block ONLY
        else
          #puts '.............  Match for: ' + val[0].chomp  + '    tag: '   + tag  +  '   Status: ' + status   ###	 File.basename(file_name)
          ###### this is main log write command
          open(dirToLog + 'update_log.txt', 'a') { |f|   f.puts   val[0].chomp +  '|'+  tag  + '|' + status + '|' + File.basename(file_name) + '|' + lineNum.to_s +  '|' + val[1].to_s    + '|' +  File.dirname(file_name) + '|' + line.chomp + '|' + IDX.to_s } #
        end

      }    ###################################   4 LOOP end

    end
###file_name





  }                                                                                                                                           #################//// Loop 03   End    Lines in file




end	     	                                                                                                                 #################///////  Loop 02 END
puts 'Ended OK'


