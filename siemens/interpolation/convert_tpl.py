import re,os,json,sys,oss2
from configparser import *
from optparse import OptionParser
class MyEnvInterpolation(ExtendedInterpolation):
    """Environment variant of interpolation.
    Enables interpolation between sections."""
    def _interpolate_some(self, parser, option, accum, rest, section, map,depth):
        rawval = parser.get(section, option, raw=True, fallback=rest)
        if depth > MAX_INTERPOLATION_DEPTH:
            raise InterpolationDepthError(option, section, rawval)
        while rest:
            p = rest.find("$")
            if p < 0:
                accum.append(rest)
                return
            if p > 0:
                accum.append(rest[:p])
                rest = rest[p:]
            # p is no longer used
            c = rest[1:2]
            if c == "$":
                accum.append("$")
                rest = rest[2:]
            elif c == "{":
                m = self._KEYCRE.match(rest)
                if m is None:
                    raise InterpolationSyntaxError(option, section,
                        "bad interpolation variable reference %r" % rest)
                path = m.group(1).split(':')
                rest = rest[m.end():]
                sect = section
                opt = option
                try:
                    if len(path) == 1:
                        opt = parser.optionxform(path[0])
                        try:
                            v = os.environ[opt].replace('"','')
                        except KeyError:
                            print("env:%r is not exist" %opt)
                    elif len(path) == 2: # "${ALICLOUD_ACM_GROUP:ENVIRONMENT}" =>${ALICLOUD_ACM_GROUP_gadev}
                        try:
                            tempvalue=path[1]
                            path[1]=os.environ[tempvalue].replace('"','')
                        except KeyError:
                            print("env:%r is not exist" %tempvalue)
                            raise KeyError
                        path[0] = "_".join(path)
                        path.pop(1)
                        # path.pop(-1)
                        opt = parser.optionxform(path[0])
                        try:
                            v = os.environ[opt].replace('"','')
                        except KeyError:
                            print("env:%r is not exist" %opt)
                            raise KeyError
                    elif len(path) == 3:  # ALICLOUD_ACCESS_KEY_SECRET = "${ACM_SECRET_KEY:ENVIRONMENT:_}"
                        try:
                            tempvalue = path[1]
                            path[1]=os.environ[tempvalue].replace('"','')
                        except KeyError:
                            print("env:%r is not exist" %tempvalue)
                            raise KeyError
                        joint_mark=path[2] #判断一下是不是连接符号
                        # path.pop(2)
                        path.pop(-1)
                        path[0] = joint_mark.join(path)
                        # path.pop(1)
                        path.pop(-1)
                        opt = parser.optionxform(path[0])
                        try:
                            v = os.environ[opt].replace('"','')
                        except KeyError:
                            print("env:%r is not exist" %opt)
                            raise KeyError
                    else:
                        raise InterpolationSyntaxError(
                            option, section,
                            "More than two ':' found: %r,currently not support" % (rest,))
                except (KeyError, NoSectionError, NoOptionError):
                    raise InterpolationMissingOptionError(
                        option, section, rawval, ":".join(path)) from None
                if "$" in v:
                    self._interpolate_some(parser, opt, accum, v, sect,
                                           dict(parser.items(sect, raw=True)),
                                           depth + 1)
                else:
                    accum.append(v)
            else:
                raise InterpolationSyntaxError(
                    option, section,
                    "'$' must be followed by '$' or '{', "
                    "found: %r" % (rest,))
class MyTerraformInterpolation(BasicInterpolation):
    """Interpolation as implemented in the classic ConfigParser.

    The option values can contain format strings which refer to terraform values in
    the remote state.

    For example:

        something: %(dir)/whatever

    would resolve the "%(dir)" to the value of dir.  All reference
    expansions are done late, on demand. If a user needs to use a bare % in
    a configuration file, she can escape it by writing %%. Other % usage
    is considered a user error and raises `InterpolationSyntaxError'."""
    _KEYCRE = re.compile(r"%\(data\.terraform_remote_state\.(\w+)\.(\w+)(\[[0-9]+\])?\)")
    def _interpolate_some(self, parser, option, accum, rest, section, map,depth):
        rawval = parser.get(section, option, raw=True, fallback=rest)
        if depth > MAX_INTERPOLATION_DEPTH:
            raise InterpolationDepthError(option, section, rawval)
        while rest:
            p = rest.find("%")
            if p < 0:
                accum.append(rest)
                return
            if p > 0:
                accum.append(rest[:p])
                rest = rest[p:]
            # p is no longer used
            c = rest[1:2]
            if c == "%":
                accum.append("%")
                rest = rest[2:]
            elif c == "(":
                m = self._KEYCRE.match(rest)
                if m is None:
                    raise InterpolationSyntaxError(option, section,
                        "bad interpolation variable reference %r" % rest)
                path=[]
                state_sect=m.group(1)
                state_output_var=m.group(2)
                state_output_index=m.group(3) # None or [0-9]+
                path.append(state_sect)
                path.append(state_output_var)
                rest = rest[m.end():]
                sect = section
                opt = option
                # oss of aliyun get
                auth = oss2.Auth(ALICLOUD_ACCESS_KEY, ALICLOUD_SECRET_KEY)
                try:
                    Path = parser_base_terr.get(state_sect, 'path').replace('"','')
                    bucket = parser_base_terr.get(state_sect, 'bucket').replace('"','')
                    key = state_output_var
                    bucket_obj = oss2.Bucket(auth, endpoint, bucket)
                    res = bucket_obj.get_object(Path)
                    data = json.loads(res.read())
                    if state_output_index:
                        path.append(state_output_index)
                        index=int(re.match("\[(\d+)\]",state_output_index).group(1))
                        v = data['modules'][0]['outputs'][key]['value'][index].replace('"','')
                    else:
                        v = data['modules'][0]['outputs'][key]['value'].replace('"','')
                except (KeyError, NoSectionError, NoOptionError):
                    raise InterpolationMissingOptionError(
                        option, section, rawval, ":".join(path)) from None
                if "%" in v:
                    self._interpolate_some(parser, opt, accum, v, sect,
                                           dict(parser.items(sect, raw=True)),
                                           depth + 1)
                else:
                    accum.append(v)
            else:
                raise InterpolationSyntaxError(
                    option, section,
                    "'$' must be followed by '$' or '{', "
                    "found: %r" % (rest,))
# global variables
cmdparser = OptionParser(version="0.0.1")
environment=os.environ.get('ENVIRONMENT').replace('"','')

ALICLOUD_ACCESS_KEY=os.environ.get('ALICLOUD_ACCESS_KEY'+'_'+str.upper(environment)).replace('"','') # use by terraform Interpolation
ALICLOUD_SECRET_KEY=os.environ.get('ALICLOUD_SECRET_KEY'+'_'+str.upper(environment)).replace('"','')
endpoint = "http://oss-cn-shanghai.aliyuncs.com"
result_val_dic={}
# verbose=True
# cmd option get
cmdparser.add_option("-t","--terraform-config",action="store",dest="terraform_config",default="config/terraform_remote_state.conf",help="terraform config")
cmdparser.add_option("-c","--config",action="store",dest="config_file",default="config/variables.conf",help="variables config")
cmdparser.add_option("-f","--file",action="store",dest="file",default="template.yml",help="convert dest file")
cmdparser.add_option("-v","--verbose",action="store",dest="verbose",default=True,help="verbose")

(options,args) = cmdparser.parse_args()

if not options.terraform_config:
    cmdparser.error("terraform remote config must give")
else:
    terraform_config = options.terraform_config

if not options.config_file:
    cmdparser.error("var config file must give")
else:
    config_file = options.config_file
if not options.file:
    cmdparser.error("template file must give")
else:
    file = options.file
    new_file = file
if not options.verbose:
    cmdparser.error("verbose must give[True|False]")
else:
    if options.verbose == "True":
        verbose = True
    elif options.verbose == "False":
        verbose = False
    else:
        verbose = options.verbose

parser_base_terr = ConfigParser(interpolation=MyEnvInterpolation())
parser_base_terr.read(terraform_config)
parser_base_terr.optionxform = lambda optionstr: optionstr


if not environment or not ALICLOUD_ACCESS_KEY or not ALICLOUD_SECRET_KEY:
    # raise HaveNoEnvError
    print("have no ENVIRONMENT/ALICLOUD_ACCESS_KEY/ALICLOUD_SECRET_KEY")
    exit(2)
#First conversion of env vairiables
parser_env=ConfigParser(interpolation=MyEnvInterpolation())
parser_env.optionxform = lambda optionstr: optionstr
parser_env.read([config_file])
for sect_specified in [environment,'default']:
    for element_option in parser_env.options(sect_specified):
        parser_env[sect_specified][element_option]=parser_env.get(sect_specified,element_option)

fp_obj=open(config_file,'w')
parser_env.write(fp_obj)
fp_obj.close()

#For the second C conversion, read variables.conf and write variables.conf
parser_terraform=ConfigParser(interpolation=MyTerraformInterpolation())
parser_terraform.optionxform = lambda optionstr: optionstr
parser_terraform.read([config_file])

for sect_specified in [environment,'default']:
    for element_option in parser_terraform.options(sect_specified):
        parser_terraform[sect_specified][element_option]=parser_terraform.get(sect_specified,element_option)
fp_tr_obj=open(config_file,'w')
parser_terraform.write(fp_tr_obj)
fp_tr_obj.close()

# vault conversion

#Read and look for variables in the template file, walk through the variables, then go to config file get, then replace the template file
def getValFromTempFile():
    # find variables of template file, and get var value and var ref into the dict result_val_dic
    with open(file,"r") as fp:
        data=fp.read()
        variables=re.findall(r".*(\$\[\w+\]).*",data)
        variables_new = sorted(set(variables), key=variables.index)
        for var_ref in variables_new:
            var_name = re.match(r"\$\[(\w+)\]",var_ref).group(1)
            parser_val=ConfigParser()
            parser_val.read([config_file])
            try:
                result_val=parser_val.get(environment,var_name)
            except NoOptionError as e:
                print("use default value for %s" %var_name)
                try:
                    result_val=parser_val.get('default',var_name)

                except NoOptionError as e:
                    print("please give var: %s" %var_name)
                    exit(2)
            if result_val:
                result_val_dic[var_ref]=result_val
            else:
                print("%r is None" %var_name)
    return result_val_dic
def getTemplateContentAndReplace(result_val_dic):
    # get file content and replace var into it ,store into a variable result_data
    with open(file,'r') as fp:
        data=fp.read()
        for key in result_val_dic:
            data=data.replace(key,result_val_dic[key])
        return data
# hidden aliyun data
def hiddenSensPrint(displayed_data):
    find_dict=re.findall(r"\s*ALICLOUD_.*_KEY.*:\s*(.+)\s*",displayed_data)
    if find_dict:
        ali_key_set=set(find_dict)
        for key in ali_key_set:
            key_val=(len(key) - 4) * '*' + key[-4:]
            displayed_data=displayed_data.replace(key,key_val)
        print(displayed_data)
def setTemplateFile(result_data):
    # you can write into file directly
    displayed_data=result_data
    if verbose:
        hiddenSensPrint(displayed_data)
    with open(new_file,'w') as fp:
        fp.write(result_data)

result_val_dic=getValFromTempFile()
result_data=getTemplateContentAndReplace(result_val_dic)
setTemplateFile(result_data)