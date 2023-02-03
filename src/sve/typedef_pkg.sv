package typedef_pkg;

    import uvm_pkg::*;
    typedef     uvm_sequence #(uvm_sequence_item)   uvm_virtual_sequence;
 
    typedef     int                                 vector [];
    typedef     real                                map_flt [string];
    typedef     int                                 map_int [string];

    typedef     enum    {
                            IDLE = 0,
                            READ = 1,
                            WRITE = 2
                        }                           t_recorder_db_mode;
endpackage

