#function load(configuration::PredictionGameConfiguration, file::File, generation::Int)
#
#    ecosystem_creator = make_ecosystem_creator(configuration)
#
#
#end
#
#function load(configuration::PredictionGameConfiguration, archive_path::String, generation::Int)
#    file = h5open(archive_path, "r")
#    ecosystem_creator, ecosystem = load(configuration, file, generation)
#    close(file)
#    return ecosystem_creator, ecosystem
#end