#!/usr/bin/ruby
#
# Author: Sarn Wattansri
# Date: 4/10/12
# Program: monitor.rb
# Objective: This program monitors the user logins periodically
#            If there are changes in login status of the users
#            at two different times, the changes will be recorded
#            in the log file called monitor.log

require 'yaml'
require 'tempfile'
require 'doconfig'

#*******************************run_last()*******************************
def run_last(fname)
    lastout = %x[last -50i]
    open(fname,"w") { |f| f.write(lastout) }
end

#*****************************show_updates()*****************************
def show_updates(fname)
    count = 0
    open(fname,"r").each do |line|
        lr = line.unpack('A9x13A17A11A6x2A15')
        lr[1] = "" if not @ipflag
        @log.write("\n" + lr[0] + "   " + lr[1] + "  " + 
                   lr[2] + " " + lr[3])
        if count > @pagesize
            @log.write("\n"*5); count = 0
        end
        if lr[4].include? "still logged in" 
            @log.write(" logged in")
        else
            @log.write(" - " + lr[4] + " logged out")
        end
        count += 1
    end
end

#*****************************lock_stdout()******************************
def lock_stdout()
    $stdout = File.open("/dev/null","w")
end

#*****************************lock_stderr()******************************
def lock_stderr()
    $stderr = File.open("/dev/null","w")
end

#****************************compare_lasts()*****************************
def compare_lasts(fn1, fn2)
    f1 = File.readlines(fn1)
    f2 = File.readlines(fn2)
    File.open("diff.txt","w") {|f| f.write(f2-f1)} 
    show_updates("diff.txt") 
end

#******************************add_log()*******************************
def add_log(msg)
    @log.write("\nTime: " + Time.new.inspect + " : " + msg)
end

#******************************write_log()*******************************
def write_log()
    @log.rewind
    File.open('readmonitorlog.txt','a'){|f| f.write("Log time: " + 
                                        Time.new.inspect + "\n");
                                            f.write(@log.read) }
end

#****************************del_valid_file()****************************
def del_valid_file(fn)
    File.delete(fn) if File.exist?(fn) and File.writable?(fn)
end

#*******************************cleanup()********************************
def cleanup()
    del_valid_file("diff.txt")
    del_valid_file("last_before.txt")
    del_valid_file("last_after.txt")    
    del_valid_file("myfile")
end

#*****************************watch_users()******************************
def watch_users()

    hup_flag = false

    trap('SIGHUP') { hup_flag = true; cfb = read_config(); 
                     add_log("config file was re-read");
                     open("myfile","w") {|f| Marshal.dump(cfb,f)}; } 
    trap('SIGTERM') {add_log("daemon is finished: terminated by user.");
                     @log.write("\n" + "-"*58 + "\n");
                     write_log(); cleanup(); exit }
    trap('USR1') { create_config(); 
                   add_log("config file was re-written.");
                   Process.kill("HUP",0) }

    lock_stdout()
    lock_stderr()
    run_last("last_before.txt")
    cfb = read_config()
    count = 0
    while true do
        #if hup_flag on, update configuration values
        if hup_flag == true 
            open("myfile") {|f| cfb = Marshal.load(f)}
            hup_flag = false
        end

        @pagesize = cfb['page_size']
        duration, period = cfb['duration'].to_i, cfb['period'].to_i
        ip, frequency = cfb['show_ip_address'], cfb['frequency']
        if ip.include? 'Y' or ip.include? 'y' 
            @ipflag = true
        else
            @ipflag = false
        end
        period = 5 if period <= 0 #Sets the default period

        if duration == 0 or count == (duration / period).to_i 
            add_log("daemon is finished: duration is complete.")
        end

        sleep(period)
        run_last("last_after.txt")
        compare_lasts("last_before.txt","last_after.txt")
        File.rename("last_after.txt","last_before.txt")
        @current_time = Time.now.to_i
        if @current_time - @beg_time > frequency then
            @beg_time = Time.now.to_i
            Process.kill("USR1",0)
        end
        count += 1 if duration != -1
    end
    @log.write("\n" + "-"*58 + "\n")
    write_log()
    cleanup()
    exit
end

@log = Tempfile.new('monitor.log')
@log.write("log items:\n")
create_config()
@beg_time = Time.now.to_i
watch_users()
exit
